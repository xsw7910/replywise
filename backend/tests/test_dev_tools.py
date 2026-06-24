from fastapi.testclient import TestClient

from app.config import settings


def _auth(client: TestClient, suffix: str) -> dict[str, str]:
    response = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": f"dev-tools-{suffix}",
            "deviceId": f"dev-tools-device-{suffix}",
            "platform": "android",
        },
    )
    return {"Authorization": f"Bearer {response.json()['accessToken']}"}


def test_dev_endpoints_are_disabled_by_default(client: TestClient) -> None:
    auth = _auth(client, "disabled")
    response = client.post("/v1/dev/add-credits", json={"amount": 10}, headers=auth)
    assert response.status_code == 404


def test_dev_endpoints_require_auth_when_enabled(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    response = client.post("/v1/dev/add-credits", json={"amount": 10})
    assert response.status_code == 401


def test_reset_usage_works(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    auth = _auth(client, "reset")

    assert client.post("/v1/dev/add-credits", json={"amount": 10}, headers=auth).status_code == 200
    assert client.post(
        "/v1/reply",
        json={"incoming": "Hello", "guidance": "Reply warmly"},
        headers={**auth, "X-Idempotency-Key": "dev-reset-reply"},
    ).status_code == 200

    response = client.post("/v1/dev/reset-usage", headers=auth)
    assert response.status_code == 200
    me = client.get("/v1/me", headers=auth).json()
    assert me["freeUsesUsed"] == 0
    assert me["paidCredits"] == 0


def test_reset_usage_accepts_safe_overrides(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    auth = _auth(client, "reset-overrides")

    response = client.post(
        "/v1/dev/reset-usage",
        json={"freeUsesUsed": 2, "paidCredits": 3},
        headers=auth,
    )
    assert response.status_code == 200
    me = client.get("/v1/me", headers=auth).json()
    assert me["freeUsesUsed"] == 2
    assert me["paidCredits"] == 3


def test_add_credits_works_and_validates_amount(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    auth = _auth(client, "credits")

    response = client.post("/v1/dev/add-credits", json={"amount": 10}, headers=auth)
    assert response.status_code == 200
    assert client.get("/v1/me", headers=auth).json()["paidCredits"] == 10

    invalid = client.post("/v1/dev/add-credits", json={"amount": 1001}, headers=auth)
    assert invalid.status_code == 400


def test_set_premium_works(client: TestClient, monkeypatch) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    auth = _auth(client, "premium")

    enabled = client.post(
        "/v1/dev/set-premium",
        json={"isPremium": True},
        headers=auth,
    )
    assert enabled.status_code == 200
    premium_me = client.get("/v1/me", headers=auth).json()
    assert premium_me["isPremium"] is True
    assert premium_me["freeUsesLeft"] is None

    disabled = client.post(
        "/v1/dev/set-premium",
        json={"isPremium": False},
        headers=auth,
    )
    assert disabled.status_code == 200
    standard_me = client.get("/v1/me", headers=auth).json()
    assert standard_me["isPremium"] is False
    assert standard_me["freeUsesLeft"] == 5


def test_dev_premium_override_is_ignored_when_dev_tools_disabled(
    client: TestClient, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "dev_tools_enabled", True)
    auth = _auth(client, "premium-disabled")
    assert client.post(
        "/v1/dev/set-premium",
        json={"isPremium": True},
        headers=auth,
    ).status_code == 200
    assert client.get("/v1/me", headers=auth).json()["isPremium"] is True

    monkeypatch.setattr(settings, "dev_tools_enabled", False)
    me = client.get("/v1/me", headers=auth).json()
    assert me["isPremium"] is False
    assert me["freeUsesLeft"] == 5
