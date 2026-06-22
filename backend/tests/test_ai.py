from fastapi.testclient import TestClient

from app.api.v1.ai import get_ai_service
from app.config import settings
from app.main import app
from app.services.ai_service import AIService


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
