import asyncio

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models.user import User
from app.services.token_service import decode_token, hash_device


def _anonymous_payload(app_user_id: str, device_id: str) -> dict[str, str]:
    return {
        "appUserId": app_user_id,
        "deviceId": device_id,
        "platform": "android",
    }


def test_anonymous_creates_user(client: TestClient) -> None:
    resp = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("auth-user-1", "dev-1"),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["accessToken"]
    assert body["refreshToken"]
    assert body["expiresIn"] == 604800
    assert body["me"]["appUserId"] == "auth-user-1"
    assert isinstance(body["me"]["userId"], int)
    assert "access_token" not in body
    assert "app_user_id" not in body["me"]


def test_anonymous_same_app_user_id_returns_same_user_id(client: TestClient) -> None:
    payload = _anonymous_payload("auth-user-2", "dev-2")
    r1 = client.post("/v1/auth/anonymous", json=payload)
    r2 = client.post("/v1/auth/anonymous", json=payload)
    assert r1.json()["me"]["userId"] == r2.json()["me"]["userId"]


def test_me_without_auth_returns_401(client: TestClient) -> None:
    resp = client.get("/v1/me")
    assert resp.status_code == 401
    assert resp.headers["www-authenticate"] == "Bearer"


def test_me_with_valid_token(client: TestClient) -> None:
    anon = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("me-user-1", "dev-me-1"),
    )
    token = anon.json()["accessToken"]
    resp = client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["appUserId"] == "me-user-1"


def test_me_with_invalid_token_returns_401(client: TestClient) -> None:
    resp = client.get("/v1/me", headers={"Authorization": "Bearer not.a.valid.token"})
    assert resp.status_code == 401


def test_me_ignores_forged_user_id(client: TestClient) -> None:
    # A correctly-signed token for one user cannot access another user's data;
    # identity comes only from the token payload, not a spoofed header.
    anon = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("me-user-2", "dev-me-2"),
    )
    token = anon.json()["accessToken"]
    resp = client.get(
        "/v1/me",
        headers={"Authorization": f"Bearer {token}", "X-App-User-Id": "some-other-user"},
    )
    assert resp.status_code == 200
    assert resp.json()["appUserId"] == "me-user-2"


def test_refresh_returns_new_access_token(client: TestClient) -> None:
    anon = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("refresh-user-1", "dev-r-1"),
    )
    refresh_token = anon.json()["refreshToken"]
    resp = client.post("/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert resp.status_code == 200
    body = resp.json()
    assert body["accessToken"]
    assert body["expiresIn"] == 604800


def test_refresh_new_token_grants_me_access(client: TestClient) -> None:
    anon = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("refresh-user-2", "dev-r-2"),
    )
    refresh_token = anon.json()["refreshToken"]
    new_token = client.post(
        "/v1/auth/refresh", json={"refreshToken": refresh_token}
    ).json()["accessToken"]
    resp = client.get("/v1/me", headers={"Authorization": f"Bearer {new_token}"})
    assert resp.status_code == 200
    assert resp.json()["appUserId"] == "refresh-user-2"


def test_refresh_with_invalid_token_returns_401(client: TestClient) -> None:
    resp = client.post("/v1/auth/refresh", json={"refreshToken": "bad.token.here"})
    assert resp.status_code == 401


def test_refresh_with_access_token_returns_401(client: TestClient) -> None:
    anon = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("refresh-user-3", "dev-r-3"),
    )
    access_token = anon.json()["accessToken"]
    resp = client.post("/v1/auth/refresh", json={"refreshToken": access_token})
    assert resp.status_code == 401


def test_tokens_include_required_identity_and_security_claims(client: TestClient) -> None:
    response = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("claims-user", "claims-device"),
    ).json()

    required = {
        "user_id",
        "app_user_id",
        "device_hash",
        "iat",
        "exp",
        "jti",
        "token_version",
        "token_type",
    }
    access_claims = decode_token(response["accessToken"])
    refresh_claims = decode_token(response["refreshToken"])

    assert required <= access_claims.keys()
    assert required <= refresh_claims.keys()
    assert access_claims["token_type"] == "access"
    assert refresh_claims["token_type"] == "refresh"
    assert access_claims["device_hash"] == hash_device("claims-device")
    assert refresh_claims["device_hash"] == hash_device("claims-device")


def test_reauth_binds_existing_user_to_current_device(client: TestClient) -> None:
    first = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("rebind-user", "old-device"),
    ).json()
    second = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("rebind-user", "current-device"),
    ).json()

    assert first["me"]["userId"] == second["me"]["userId"]
    second_claims = decode_token(second["accessToken"])
    assert second_claims["device_hash"] == hash_device("current-device")

    old_me = client.get(
        "/v1/me", headers={"Authorization": f"Bearer {first['accessToken']}"}
    )
    assert old_me.status_code == 401


def test_token_version_invalidation_rejects_old_token(client: TestClient) -> None:
    auth = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("version-user", "version-device"),
    ).json()
    user_id = auth["me"]["userId"]

    async def invalidate() -> None:
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(User).where(User.id == user_id))
            user = result.scalar_one()
            user.token_version += 1
            await session.commit()

    asyncio.run(invalidate())

    response = client.get(
        "/v1/me", headers={"Authorization": f"Bearer {auth['accessToken']}"}
    )
    assert response.status_code == 401

    refresh = client.post(
        "/v1/auth/refresh", json={"refreshToken": auth["refreshToken"]}
    )
    assert refresh.status_code == 401
