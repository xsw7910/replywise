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
        "Formal",
        "Casual",
        "Concise",
    ]
    assert all(item["text"] for item in body["versions"])
    assert body["why"]
    assert body["usage"]["freeUsesLeft"] == 2


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
    assert usage["freeUsesLeft"] == 2
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


class _CapturingReplyProvider:
    def __init__(self) -> None:
        self.system_prompt = ""
        self.payload: dict = {}

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.system_prompt = system_prompt
        self.payload = payload
        return json.dumps(
            {
                "versions": [
                    {"label": "Formal", "text": "Formal reply"},
                    {"label": "Casual", "text": "Casual reply"},
                    {"label": "Concise", "text": "Concise reply"},
                ],
                "why": "The requested tone and audience were applied.",
            }
        )


class _CapturingPolishProvider:
    def __init__(self) -> None:
        self.system_prompt = ""
        self.payload: dict = {}

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.system_prompt = system_prompt
        self.payload = payload
        return json.dumps(
            {
                "polished": payload["draft"].strip(),
                "changes": "Applied the requested polishing instructions.",
            }
        )


class _CapturingExplainProvider:
    def __init__(self) -> None:
        self.system_prompt = ""
        self.payload: dict = {}

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.system_prompt = system_prompt
        self.payload = payload
        return json.dumps(
            {
                "meaning": "Meaning",
                "tone": "Tone",
                "hiddenMeaning": "",
                "suggestedReplies": ["Thanks for letting me know."],
            }
        )


def test_reply_zh_locale_adds_chinese_heading_instruction(
    client: TestClient,
) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json={**_reply_payload(), "appLocale": "zh"},
            headers=_headers(client, "reply-zh-locale"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "explanation_language = Simplified Chinese." in provider.system_prompt
    assert provider.payload["explanation_language"] == "Simplified Chinese"


def test_polish_zh_locale_adds_chinese_heading_instruction(
    client: TestClient,
) -> None:
    provider = _CapturingPolishProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/polish",
            json={
                "draft": "Please review this.",
                "direction": "natural",
                "appLocale": "zh",
            },
            headers=_headers(client, "polish-zh-locale"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "explanation_language = Simplified Chinese." in provider.system_prompt
    assert provider.payload["explanation_language"] == "Simplified Chinese"


def test_explain_zh_locale_adds_chinese_heading_instruction(
    client: TestClient,
) -> None:
    provider = _CapturingExplainProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/explain",
            json={"text": "Can we reschedule?", "appLocale": "zh"},
            headers=_headers(client, "explain-zh-locale"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "explanation_language = Simplified Chinese." in provider.system_prompt
    assert provider.payload["explanation_language"] == "Simplified Chinese"


class _EchoPolishProvider:
    """Echoes back a fixed polished/changes pair, capturing the prompt.

    Simulates a model that follows the language contract: polished text stays
    in the draft's language, changes uses explanation_language. The backend
    must pass both through untouched (no translation layer).
    """

    def __init__(self, polished: str, changes: str) -> None:
        self.polished = polished
        self.changes = changes
        self.system_prompt = ""
        self.payload: dict = {}

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.system_prompt = system_prompt
        self.payload = payload
        return json.dumps({"polished": self.polished, "changes": self.changes})


def _post_polish(client: TestClient, provider, draft: str, app_locale: str, suffix: str):
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        return client.post(
            "/v1/polish",
            json={"draft": draft, "direction": "natural", "appLocale": app_locale},
            headers=_headers(client, suffix),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)


def test_polish_prompt_pins_polished_text_to_draft_language(
    client: TestClient,
) -> None:
    """English draft + Chinese app language: polished stays English, changes
    is Chinese; the prompt states the split explicitly."""
    provider = _EchoPolishProvider(
        polished="Hi, could you please send me the report today?",
        changes="语气更礼貌、更自然。",
    )
    response = _post_polish(
        client,
        provider,
        draft="Hi, can you send me the report today?",
        app_locale="zh",
        suffix="polish-lang-en-draft",
    )

    assert response.status_code == 200
    body = response.json()
    # Passed through untouched — polished is NOT translated to the app language.
    assert body["polished"] == "Hi, could you please send me the report today?"
    assert body["changes"] == "语气更礼貌、更自然。"

    # The prompt separates the two languages explicitly.
    assert "SAME language as the input" in provider.system_prompt
    assert '"changes" is an explanation ABOUT the edits' in provider.system_prompt
    assert (
        'Never translate "polished" into\n  explanation_language'
        in provider.system_prompt
    )
    assert provider.payload["explanation_language"] == "Simplified Chinese"
    # The ambiguous output-language field and raw UI locale never reach the model.
    assert "output_language" not in provider.payload
    assert "app_locale" not in provider.payload


def test_polish_chinese_draft_with_english_app_language(client: TestClient) -> None:
    provider = _EchoPolishProvider(
        polished="你好，请问今天能把报告发给我吗？",
        changes="Softened the request and made it more polite.",
    )
    response = _post_polish(
        client,
        provider,
        draft="你好，今天把报告发我。",
        app_locale="en",
        suffix="polish-lang-zh-draft",
    )

    assert response.status_code == 200
    body = response.json()
    assert body["polished"] == "你好，请问今天能把报告发给我吗？"
    assert body["changes"] == "Softened the request and made it more polite."
    assert provider.payload["explanation_language"] == "English"


def test_polish_preserves_french_and_spanish_drafts(client: TestClient) -> None:
    for draft, suffix in [
        ("Bonjour, pouvez-vous m'envoyer le rapport ?", "polish-lang-fr"),
        ("Hola, ¿puedes enviarme el informe hoy?", "polish-lang-es"),
    ]:
        provider = _EchoPolishProvider(polished=draft, changes="Minor tweaks.")
        response = _post_polish(
            client, provider, draft=draft, app_locale="zh", suffix=suffix
        )
        assert response.status_code == 200
        # The polished text keeps the draft's language even with zh app locale.
        assert response.json()["polished"] == draft
        assert "SAME language as the input" in provider.system_prompt


def test_reply_prompt_pins_reply_text_to_incoming_language(
    client: TestClient,
) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json={**_reply_payload(), "appLocale": "zh"},
            headers=_headers(client, "reply-lang-contract"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "MUST be written in the SAME language" in provider.system_prompt
    assert "incoming message" in provider.system_prompt
    # No UI-locale field may reach the model payload as an output-language hint.
    assert "output_lang" not in provider.payload
    assert "output_language" not in provider.payload
    assert "app_locale" not in provider.payload
    assert "guidance_lang" not in provider.payload
    # The UI language survives only as the clearly scoped explanation_language.
    assert provider.payload["explanation_language"] == "Simplified Chinese"
    assert (
        "explanation_language is the app interface / UI language"
        in provider.system_prompt
    )
    assert "governs ONLY the explanation fields" in provider.system_prompt


def test_missing_locale_falls_back_to_english(client: TestClient) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json=_reply_payload(),
            headers=_headers(client, "missing-app-locale"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "explanation_language = English." in provider.system_prompt
    assert provider.payload["explanation_language"] == "English"
    assert "app_locale" not in provider.payload


def test_unsupported_locale_falls_back_to_english(
    client: TestClient,
) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json={**_reply_payload(), "appLocale": "xx-unknown"},
            headers=_headers(client, "unsupported-app-locale"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert "explanation_language = English." in provider.system_prompt
    assert provider.payload["explanation_language"] == "English"
    assert "app_locale" not in provider.payload


def test_polish_optional_instructions_reach_provider(client: TestClient) -> None:
    provider = _CapturingPolishProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/polish",
            json={
                "draft": " Please review this draft. ",
                "direction": "natural",
                "guidance": " Keep the original meaning. ",
                "tone": " warm but professional ",
                "audience": " my manager ",
                "length": " shorter ",
                "extraInstruction": " Keep the opening sentence. ",
            },
            headers=_headers(client, "polish-options"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert provider.payload["guidance"] == "Keep the original meaning."
    assert provider.payload["tone"] == "warm but professional"
    assert provider.payload["audience"] == "my manager"
    assert provider.payload["length"] == "shorter"
    assert provider.payload["extra_instruction"] == "Keep the opening sentence."
    assert '"guidance" is present' in provider.system_prompt
    assert '"tone" is present' in provider.system_prompt
    assert '"audience" is present' in provider.system_prompt
    assert '"extra_instruction" is present' in provider.system_prompt


def test_polish_empty_optional_instructions_do_not_crash(
    client: TestClient,
) -> None:
    provider = _CapturingPolishProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/polish",
            json={
                "draft": "Please review this draft.",
                "direction": "natural",
                "guidance": " ",
                "tone": " ",
                "audience": " ",
                "length": " ",
                "extraInstruction": " ",
            },
            headers=_headers(client, "polish-empty-options"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert provider.payload["guidance"] is None
    assert provider.payload["tone"] is None
    assert provider.payload["audience"] is None
    assert provider.payload["length"] is None
    assert provider.payload["extra_instruction"] is None


def test_reply_custom_tone_and_audience_reach_provider(client: TestClient) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json={
                **_reply_payload(),
                "tone": " warm but professional ",
                "audience": {
                    "mode": "custom",
                    "custom": " my manager ",
                    "formality": 55,
                },
            },
            headers=_headers(client, "custom-tone-audience"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert provider.payload["tone"] == "warm but professional"
    assert provider.payload["audience"]["custom"] == "my manager"
    assert '"tone" is present' in provider.system_prompt
    assert 'audience.mode "custom"' in provider.system_prompt


def test_reply_empty_optional_tone_and_audience_do_not_crash(
    client: TestClient,
) -> None:
    provider = _CapturingReplyProvider()
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        response = client.post(
            "/v1/reply",
            json={
                **_reply_payload(),
                "tone": " ",
                "audience": {
                    "mode": "custom",
                    "custom": " ",
                    "formality": 55,
                },
            },
            headers=_headers(client, "empty-tone-audience"),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)

    assert response.status_code == 200
    assert provider.payload["tone"] is None
    assert provider.payload["audience"]["custom"] is None


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
        "Formal",
        "Casual",
        "Concise",
    ]
    assert body["usage"]["source"] == "free"


def test_mock_ai_enabled_keeps_validation_active(
    client: TestClient, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "mock_ai_enabled", True)
    response = client.post(
        "/v1/reply",
        json={**_reply_payload(), "incoming": " "},
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


def test_reply_accepts_empty_guidance(client: TestClient) -> None:
    response = client.post(
        "/v1/reply",
        json={**_reply_payload(), "guidance": ""},
        headers=_headers(client, "empty-guidance"),
    )
    assert response.status_code == 200
    assert len(response.json()["versions"]) == 3


def test_reply_accepts_missing_guidance(client: TestClient) -> None:
    payload = {k: v for k, v in _reply_payload().items() if k != "guidance"}
    response = client.post(
        "/v1/reply",
        json=payload,
        headers=_headers(client, "missing-guidance"),
    )
    assert response.status_code == 200
    assert len(response.json()["versions"]) == 3


def test_reply_still_rejects_oversized_guidance(client: TestClient) -> None:
    response = client.post(
        "/v1/reply",
        json={**_reply_payload(), "guidance": "x" * 1001},
        headers=_headers(client, "oversized-guidance"),
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INPUT_TOO_LONG"
    assert response.json()["error"]["field"] == "guidance"


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


# ── Output-language behaviour (source-text language, not UI language) ─────────
#
# The fake providers cannot make a real model pick a language, so these tests
# lock the two things the backend actually controls:
#   1. The instruction contract sent to the model (prompt wording + the fact
#      that no UI-locale field reaches the payload as an output-language hint).
#   2. Pass-through: whatever language the model returns is delivered untouched
#      (there is no server-side translation layer to override it).


class _EchoReplyProvider:
    """Returns caller-specified reply text + why, capturing the prompt/payload.

    Stands in for a model that honours the language contract; the backend must
    hand the text back untouched (no translation layer)."""

    def __init__(self, texts: tuple[str, str, str], why: str) -> None:
        self.texts = texts
        self.why = why
        self.system_prompt = ""
        self.payload: dict = {}

    async def complete(self, system_prompt: str, payload: dict) -> str:
        self.system_prompt = system_prompt
        self.payload = payload
        formal, casual, concise = self.texts
        return json.dumps(
            {
                "versions": [
                    {"label": "Formal", "text": formal},
                    {"label": "Casual", "text": casual},
                    {"label": "Concise", "text": concise},
                ],
                "why": self.why,
            }
        )


def _post_reply(
    client: TestClient,
    provider,
    *,
    incoming: str,
    app_locale: str,
    suffix: str,
    guidance: str = "",
):
    app.dependency_overrides[get_ai_service] = lambda: AIService(provider)
    try:
        return client.post(
            "/v1/reply",
            json={
                "incoming": incoming,
                "guidance": guidance,
                "guidanceLang": app_locale,
                "audience": {"mode": "auto", "formality": 50},
                "appLocale": app_locale,
            },
            headers=_headers(client, suffix),
        )
    finally:
        app.dependency_overrides.pop(get_ai_service, None)


def _assert_no_ui_language_output_hint(payload: dict, expected_explanation: str) -> None:
    """The interface language survives only as explanation_language."""
    assert payload["explanation_language"] == expected_explanation
    for leaked in ("output_language", "output_lang", "app_locale", "guidance_lang"):
        assert leaked not in payload, f"{leaked} must not reach the model payload"


def test_reply_prompt_forbids_ui_language_and_unrequested_translation(
    client: TestClient,
) -> None:
    """The reply prompt states all three rules the fix depends on."""
    provider = _EchoReplyProvider(("F", "C", "N"), why="解释")
    response = _post_reply(
        client, provider, incoming="Hi", app_locale="zh", suffix="reply-rules"
    )
    assert response.status_code == 200
    prompt = provider.system_prompt
    assert "MUST be written in the SAME language" in prompt
    assert "incoming message" in prompt
    assert "Do NOT use the app interface language" in prompt
    assert "Do NOT translate the reply unless the guidance EXPLICITLY" in prompt
    assert "must NOT change the reply's language unless it explicitly requests" in prompt


def test_reply_english_input_under_chinese_ui_stays_english(client: TestClient) -> None:
    """Scenario 1 (Reply): UI Chinese + English input → English reply."""
    english = (
        "Sure, I can send the report shortly.",
        "Yep, I'll get the report over soon!",
        "Sending the report soon.",
    )
    provider = _EchoReplyProvider(english, why="这样回复自然且礼貌。")
    response = _post_reply(
        client,
        provider,
        incoming="Can you send the report?",
        app_locale="zh",
        suffix="reply-en-under-zh",
    )
    assert response.status_code == 200
    body = response.json()
    assert [v["text"] for v in body["versions"]] == list(english)
    _assert_no_ui_language_output_hint(provider.payload, "Simplified Chinese")


def test_reply_chinese_input_under_english_ui_stays_chinese(client: TestClient) -> None:
    """Scenario 2 (Reply): UI English + Chinese input → Chinese reply."""
    chinese = ("好的，我马上发给你。", "行，我这就发～", "马上发。")
    provider = _EchoReplyProvider(chinese, why="This keeps the reply natural.")
    response = _post_reply(
        client,
        provider,
        incoming="你能把报告发给我吗？",
        app_locale="en",
        suffix="reply-zh-under-en",
    )
    assert response.status_code == 200
    body = response.json()
    assert [v["text"] for v in body["versions"]] == list(chinese)
    _assert_no_ui_language_output_hint(provider.payload, "English")


def test_reply_spanish_input_under_french_ui_stays_spanish(client: TestClient) -> None:
    """Scenario 3 (Reply): UI French + Spanish input → Spanish reply."""
    spanish = ("Claro, te envío el informe.", "¡Claro! Ya te lo mando.", "Enviando el informe.")
    provider = _EchoReplyProvider(spanish, why="La réponse reste naturelle.")
    response = _post_reply(
        client,
        provider,
        incoming="¿Puedes enviarme el informe?",
        app_locale="fr",
        suffix="reply-es-under-fr",
    )
    assert response.status_code == 200
    body = response.json()
    assert [v["text"] for v in body["versions"]] == list(spanish)
    _assert_no_ui_language_output_hint(provider.payload, "French")


def test_reply_english_input_chinese_guidance_stays_english(client: TestClient) -> None:
    """Scenario 4: English message + Chinese guidance → the reply stays English.

    The guidance changes content/tone but not the language, and the prompt says
    so explicitly. The echo model returns English; the backend passes it through.
    """
    english = (
        "Thanks — Friday works for me.",
        "Sure, Friday's good for me!",
        "Friday works.",
    )
    provider = _EchoReplyProvider(english, why="回复保持英文，符合原文语言。")
    response = _post_reply(
        client,
        provider,
        incoming="Can we reschedule our meeting?",
        app_locale="zh",
        suffix="reply-en-zh-guidance",
        guidance="礼貌地告诉他我周五有空。",
    )
    assert response.status_code == 200
    body = response.json()
    assert [v["text"] for v in body["versions"]] == list(english)
    assert (
        "must NOT change the reply's language unless it explicitly requests"
        in provider.system_prompt
    )


def test_reply_explicit_translation_guidance_allows_chinese(client: TestClient) -> None:
    """Scenario 5: guidance that explicitly asks to reply in Chinese is allowed.

    The prompt permits a language switch on explicit request; the echo model
    returns Chinese and the backend passes it through unchanged.
    """
    chinese = ("好的，我们周五见。", "行，那周五见～", "周五见。")
    provider = _EchoReplyProvider(chinese, why="Requested Chinese output.")
    response = _post_reply(
        client,
        provider,
        incoming="Can we reschedule our meeting?",
        app_locale="en",
        suffix="reply-explicit-zh",
        guidance="Reply in Chinese.",
    )
    assert response.status_code == 200
    body = response.json()
    assert [v["text"] for v in body["versions"]] == list(chinese)
    assert "unless the guidance EXPLICITLY" in provider.system_prompt


def test_reply_explanation_follows_settings_while_reply_follows_source(
    client: TestClient,
) -> None:
    """Scenario 6: UI Chinese + English input → English reply, Chinese "why"."""
    english = ("Sure, sending it now.", "Yep, on it!", "Sending now.")
    provider = _EchoReplyProvider(english, why="这样表达清晰又礼貌。")
    response = _post_reply(
        client,
        provider,
        incoming="Please send the file.",
        app_locale="zh",
        suffix="reply-explanation-zh",
    )
    assert response.status_code == 200
    body = response.json()
    # Main reply follows the source (English); the explanation follows Settings.
    assert [v["text"] for v in body["versions"]] == list(english)
    assert body["why"] == "这样表达清晰又礼貌。"
    assert provider.payload["explanation_language"] == "Simplified Chinese"
    assert '"why" is an explanation ABOUT the reply' in provider.system_prompt


def test_polish_no_translation_without_explicit_request(client: TestClient) -> None:
    """Scenario 7: Polish never translates unless explicitly asked."""
    draft = "Hi, can you send me the report today?"
    provider = _EchoPolishProvider(
        polished="Hi, could you please send me the report today?",
        changes="更礼貌、更自然。",
    )
    response = _post_polish(
        client, provider, draft=draft, app_locale="zh", suffix="polish-no-translate"
    )
    assert response.status_code == 200
    assert response.json()["polished"] == "Hi, could you please send me the report today?"
    assert "Improve it without translating it" in provider.system_prompt
    assert "Ignore the app interface language" in provider.system_prompt
    _assert_no_ui_language_output_hint(provider.payload, "Simplified Chinese")


def test_polish_spanish_input_under_french_ui_stays_spanish(client: TestClient) -> None:
    """Scenario 3 (Polish): UI French + Spanish input → Spanish polished text."""
    draft = "Hola, ¿puedes enviarme el informe hoy?"
    provider = _EchoPolishProvider(
        polished="Hola, ¿podrías enviarme el informe hoy, por favor?",
        changes="Ton plus poli.",
    )
    response = _post_polish(
        client, provider, draft=draft, app_locale="fr", suffix="polish-es-under-fr"
    )
    assert response.status_code == 200
    assert response.json()["polished"] == "Hola, ¿podrías enviarme el informe hoy, por favor?"
    _assert_no_ui_language_output_hint(provider.payload, "French")


def test_response_shapes_unchanged_by_language_fix(client: TestClient) -> None:
    """Scenario 8: the public Reply/Polish response shapes are unchanged."""
    reply = client.post(
        "/v1/reply", json=_reply_payload(), headers=_headers(client, "shape-reply")
    )
    assert reply.status_code == 200
    assert set(reply.json()) >= {"versions", "why", "usage"}
    assert set(reply.json()["versions"][0]) == {"label", "text"}

    polish = client.post(
        "/v1/polish",
        json={"draft": "Hello there", "direction": "natural"},
        headers=_headers(client, "shape-polish"),
    )
    assert polish.status_code == 200
    assert set(polish.json()) >= {"polished", "changes", "usage"}


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
    text = 'Sure! {"versions":[{"label":"Formal","text":"Hi."}],"why":"Good."}'
    parsed = json.loads(_extract_json_object(text))
    assert parsed["versions"][0]["label"] == "Formal"


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
    """Returns the exact JSON schema that OpenAI produces when given the new explicit prompts.

    The reply intentionally uses the LEGACY version labels: a drifting model
    (or an old cached prompt) may still emit them, and the service must
    normalize them to Formal/Casual/Concise.
    """

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
    # Legacy labels from the provider are normalized to the current ones.
    assert [v["label"] for v in body["versions"]] == ["Formal", "Casual", "Concise"]
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
