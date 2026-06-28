import json

import pytest
from fastapi.testclient import TestClient

from app.api.v1.ai import get_ai_service
from app.config import settings
from app.main import app
from app.services.ai_provider import AIProviderError, FakeAIProvider, OpenAIProvider
from app.services.ai_service import AIService, _extract_json_object, _strip_json_fence
import app.api.v1.ai as ai_module


def _token(client: TestClient, suffix: str) -> str:
    response = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": f"ai-user-{suffix}",
            "deviceId": f"ai-device-{suffix}",
            "platform": "android",
        },
    )
    return response.json()["accessToken"]


def _headers(client: TestClient, suffix: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {_token(client, suffix)}",
        "X-Idempotency-Key": f"ai-{suffix}",
    }


def _reply_payload() -> dict:
    return {
        "incoming": "Can we move the meeting to next week?",
        "guidance": "Agree, but ask to confirm by Wednesday",
        "guidanceLang": "en",
        "outputLang": "fr",
        "audience": {"mode": "auto", "formality": 60},
    }


def test_ai_routes_require_authentication(client: TestClient) -> None:
    assert client.post("/v1/reply", json=_reply_payload()).status_code == 401
    assert (
        client.post(
            "/v1/polish",
            json={"draft": "Hello there", "direction": "natural"},
        ).status_code
        == 401
    )
    assert client.post("/v1/explain", json={"text": "Hello"}).status_code == 401


def test_reply_success_has_three_english_versions(client: TestClient) -> None:
    response = client.post(
        "/v1/reply",
        json=_reply_payload(),
        headers=_headers(client, "reply-success"),
    )
    assert response.status_code == 200
    body = response.json()
    assert [item["label"] for item in body["versions"]] == [
        "Professional",
        "Friendly",
        "Short",
    ]
    assert all(item["text"] for item in body["versions"])
    assert body["why"]
    assert body["usage"]["freeUsesLeft"] == 4


def test_polish_success_preserves_the_draft(client: TestClient) -> None:
    response = client.post(
        "/v1/polish",
        json={
            "draft": "I wanted to check on the report.",
            "direction": "professional",
            "guidanceLang": "en",
        },
        headers=_headers(client, "polish-success"),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["polished"] == "I wanted to check on the report."
    assert body["changes"]
    usage = body["usage"]
    assert usage["freeUsesLeft"] == 4
    assert usage["source"] == "free"
    assert usage["creditsUsed"] == 1


def test_explain_success_returns_all_sections(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={"text": "Things are hectic on our end.", "explainLang": "en"},
        headers=_headers(client, "explain-success"),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["meaning"]
    assert body["tone"]
    assert "hiddenMeaning" in body
    assert 1 <= len(body["suggestedReplies"]) <= 3


def test_empty_and_oversized_input_use_consistent_errors(client: TestClient) -> None:
    headers = _headers(client, "validation")
    empty = client.post(
        "/v1/reply",
        json={**_reply_payload(), "incoming": "   "},
        headers=headers,
    )
    assert empty.status_code == 400
    assert empty.json()["error"]["code"] == "VALIDATION_ERROR"
    assert empty.json()["error"]["field"] == "incoming"

    oversized = client.post(
        "/v1/polish",
        json={"draft": "x" * 4001, "direction": "natural"},
        headers=headers,
    )
    assert oversized.status_code == 400
    assert oversized.json()["error"]["code"] == "INPUT_TOO_LONG"
    assert oversized.json()["error"]["field"] == "draft"


def test_custom_polish_requires_custom_guidance(client: TestClient) -> None:
    response = client.post(
        "/v1/polish",
        json={"draft": "Hello", "direction": "custom", "custom": " "},
        headers=_headers(client, "custom-validation"),
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_polish_custom_guidance_accepts_1000_chars(client: TestClient) -> None:
    # A 1000-char guidance item saved in the library must be usable in Polish.
    response = client.post(
        "/v1/polish",
        json={"draft": "Hello there", "direction": "custom", "custom": "x" * 1000},
        headers=_headers(client, "custom-boundary-ok"),
    )
    assert response.status_code == 200


def test_polish_custom_guidance_rejects_over_1000_chars(client: TestClient) -> None:
    response = client.post(
        "/v1/polish",
        json={"draft": "Hello there", "direction": "custom", "custom": "x" * 1001},
        headers=_headers(client, "custom-boundary-too-long"),
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INPUT_TOO_LONG"
    assert response.json()["error"]["field"] == "custom"


class _FenceProvider:
    async def complete(self, system_prompt: str, payload: dict) -> str:
        return """```json
{"polished":"Hello there.","changes":"Improved punctuation."}
```"""


class _MalformedProvider:
    def __init__(self) -> None:
        self.calls = 0

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.calls += 1
        return "not json"


class _UnavailableProvider:
    async def complete(self, system_prompt: str, payload: dict) -> str:
        raise TimeoutError("provider timeout")


class _ExplodingProvider:
    async def complete(self, system_prompt: str, payload: dict) -> str:
        raise AssertionError("external provider should not be called")


class _SanitizedProviderFailure:
    async def complete(self, system_prompt: str, payload: dict) -> str:
        try:
            raise RuntimeError("raw-provider-detail sk-secret-value")
        except RuntimeError as error:
            raise AIProviderError(
                "MODEL_CONFIGURATION_ERROR",
                "The AI service is temporarily unavailable.",
                503,
            ) from error


def test_mock_ai_enabled_uses_local_fake_provider(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "mock_ai_enabled", True)
    monkeypatch.setattr(ai_module, "_ai_service", AIService(_ExplodingProvider()))

    response = client.post(
        "/v1/reply",
        json=_reply_payload(),
        headers=_headers(client, "mock-ai-reply"),
    )
    assert response.status_code == 200
    body = response.json()
    assert [item["label"] for item in body["versions"]] == [
        "Professional",
        "Friendly",
        "Short",
    ]
    assert body["usage"]["source"] == "free"


def test_mock_ai_enabled_keeps_validation_active(
    client: TestClient, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "mock_ai_enabled", True)
    response = client.post(
        "/v1/reply",
        json={**_reply_payload(), "guidance": " "},
        headers=_headers(client, "mock-ai-validation"),
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_json_fence_is_stripped(client: TestClient) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(_FenceProvider())
    try:
        response = client.post(
            "/v1/polish",
            json={"draft": "Hello", "direction": "natural"},
            headers=_headers(client, "fence"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert response.json()["polished"] == "Hello there."


def test_malformed_model_output_retries_once_then_errors(client: TestClient) -> None:
    provider = _MalformedProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json=_reply_payload(),
            headers=_headers(client, "malformed"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 502
    assert response.json()["error"]["code"] == "MODEL_PARSE_ERROR"
    assert provider.calls == 2


def test_provider_failure_returns_consistent_unavailable_error(
    client: TestClient,
) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(
        _UnavailableProvider()
    )
    try:
        response = client.post(
            "/v1/reply",
            json=_reply_payload(),
            headers=_headers(client, "unavailable"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "MODEL_UNAVAILABLE"


def test_provider_error_does_not_expose_raw_provider_details(
    client: TestClient,
) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(
        _SanitizedProviderFailure()
    )
    try:
        response = client.post(
            "/v1/reply",
            json=_reply_payload(),
            headers=_headers(client, "sanitized-provider-error"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 503
    body = response.json()
    assert body["error"]["code"] == "MODEL_CONFIGURATION_ERROR"
    assert body["error"]["message"] == "The AI service is temporarily unavailable."
    assert "raw-provider-detail" not in response.text
    assert "sk-secret-value" not in response.text


def test_openai_provider_selected_when_api_key_set(monkeypatch) -> None:
    monkeypatch.setattr(settings, "openai_api_key", "sk-fake-key")
    monkeypatch.setattr(settings, "openai_model", "gpt-4o-mini")
    svc = ai_module._make_default_service()
    assert isinstance(svc.provider, OpenAIProvider)


def test_fake_provider_used_when_no_api_key(monkeypatch) -> None:
    monkeypatch.setattr(settings, "openai_api_key", "")
    svc = ai_module._make_default_service()
    assert isinstance(svc.provider, FakeAIProvider)


def test_explain_daily_limit_is_independent_from_billing(
    client: TestClient, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "explain_daily_limit", 1)
    headers = _headers(client, "explain-limit")
    first = client.post("/v1/explain", json={"text": "Hello"}, headers=headers)
    second = client.post("/v1/explain", json={"text": "Hello"}, headers=headers)

    assert first.status_code == 200
    assert second.status_code == 429
    assert second.json()["error"]["code"] == "RATE_LIMITED"


# ── Parser unit tests ─────────────────────────────────────────────────────────


def test_strip_json_fence_removes_json_language_tag() -> None:
    fenced = '```json\n{"key":"value"}\n```'
    assert _strip_json_fence(fenced) == '{"key":"value"}'


def test_strip_json_fence_removes_plain_fence() -> None:
    fenced = '```\n{"key":"value"}\n```'
    assert _strip_json_fence(fenced) == '{"key":"value"}'


def test_strip_json_fence_passes_through_clean_json() -> None:
    clean = '{"key":"value"}'
    assert _strip_json_fence(clean) == clean


def test_extract_json_object_finds_object_in_leading_prose() -> None:
    prose = 'Here is the result: {"polished":"Hello.","changes":"Fixed."} That is all.'
    assert json.loads(_extract_json_object(prose)) == {
        "polished": "Hello.",
        "changes": "Fixed.",
    }


def test_extract_json_object_handles_nested_objects() -> None:
    text = 'Sure! {"versions":[{"label":"Professional","text":"Hi."}],"why":"Good."}'
    parsed = json.loads(_extract_json_object(text))
    assert parsed["versions"][0]["label"] == "Professional"


def test_extract_json_object_handles_braces_inside_strings() -> None:
    text = 'Here: {"meaning":"Use {curly} braces carefully.","tone":"Casual."}'
    parsed = json.loads(_extract_json_object(text))
    assert "{curly}" in parsed["meaning"]


def test_extract_json_object_raises_on_no_object() -> None:
    with pytest.raises(ValueError, match="No JSON object found"):
        _extract_json_object("no json here")


def test_extract_json_object_raises_on_unclosed_object() -> None:
    with pytest.raises(ValueError, match="No complete JSON object found"):
        _extract_json_object('{"unclosed": "object"')


# ── Integration tests for new parsing paths ───────────────────────────────────


class _ProseWrappedProvider:
    """Simulates a model that wraps its JSON in prose despite instructions."""

    async def complete(self, system_prompt: str, payload: dict) -> str:
        body = json.dumps({"polished": "Hello there.", "changes": "Improved punctuation."})
        return f"Sure! Here is the polished version:\n\n{body}\n\nLet me know if you need anything else."


class _ExplicitSchemaProvider:
    """Returns the exact JSON schema that OpenAI produces when given the new explicit prompts."""

    async def complete(self, system_prompt: str, payload: dict) -> str:
        task = payload.get("task")
        if task == "reply":
            return json.dumps({
                "versions": [
                    {"label": "Professional", "text": "Thank you for reaching out. I would be happy to assist."},
                    {"label": "Friendly", "text": "Hey, thanks for getting in touch! Happy to help."},
                    {"label": "Short", "text": "Thanks — sounds good!"},
                ],
                "why": "These replies are natural and match the requested tone.",
            })
        if task == "polish":
            return json.dumps({
                "polished": payload["draft"].strip(),
                "changes": "Minor grammar and flow improvements.",
            })
        return json.dumps({
            "meaning": "The sender is requesting a meeting reschedule.",
            "tone": "Polite and professional.",
            "hiddenMeaning": "",
            "suggestedReplies": ["Sure, Friday works.", "Let me check my calendar."],
        })


def test_json_embedded_in_prose_is_extracted(client: TestClient) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(_ProseWrappedProvider())
    try:
        response = client.post(
            "/v1/polish",
            json={"draft": "Hello", "direction": "natural"},
            headers=_headers(client, "prose-wrapped"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert response.json()["polished"] == "Hello there."


def test_openai_schema_compliant_response_parses_reply(client: TestClient) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(_ExplicitSchemaProvider())
    try:
        response = client.post(
            "/v1/reply",
            json=_reply_payload(),
            headers=_headers(client, "explicit-schema-reply"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    body = response.json()
    assert [v["label"] for v in body["versions"]] == ["Professional", "Friendly", "Short"]
    assert all(v["text"] for v in body["versions"])
    assert body["why"]


def test_openai_schema_compliant_response_parses_explain(client: TestClient) -> None:
    app.dependency_overrides[get_ai_service] = lambda: AIService(_ExplicitSchemaProvider())
    try:
        response = client.post(
            "/v1/explain",
            json={"text": "Can we reschedule?", "explainLang": "en"},
            headers=_headers(client, "explicit-schema-explain"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    body = response.json()
    assert body["meaning"]
    assert body["tone"]
    assert "hiddenMeaning" in body
    assert 1 <= len(body["suggestedReplies"]) <= 3
