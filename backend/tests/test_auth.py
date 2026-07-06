import asyncio

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.database import AsyncSessionLocal, Base
from app.models.usage import UsageSummary
from app.models.user import User
from app.services.auth_service import resolve_anonymous_user
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


def test_same_app_user_id_cannot_move_credits_to_another_device(
    client: TestClient,
) -> None:
    first = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("rebind-user", "old-device"),
    )
    second = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("rebind-user", "current-device"),
    )

    assert first.status_code == 200
    assert second.status_code == 409
    old_me = client.get(
        "/v1/me",
        headers={"Authorization": f"Bearer {first.json()['accessToken']}"},
    )
    assert old_me.status_code == 200


def test_reinstall_reuses_existing_user_and_paid_credits(
    client: TestClient,
) -> None:
    first = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("paid-owner-before-reinstall", "paid-device"),
    ).json()
    user_id = first["me"]["userId"]

    async def grant_credits() -> None:
        async with AsyncSessionLocal() as session:
            summary = await session.get(UsageSummary, user_id)
            summary.paid_credits = 50
            await session.commit()

    asyncio.run(grant_credits())

    restored = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("new-install-app-user-id", "paid-device"),
    )
    assert restored.status_code == 200
    assert restored.json()["me"] == first["me"]

    me = client.get(
        "/v1/me",
        headers={"Authorization": f"Bearer {restored.json()['accessToken']}"},
    )
    assert me.status_code == 200
    assert me.json()["paidCredits"] == 50


def test_new_device_hash_creates_a_different_user(client: TestClient) -> None:
    first = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("new-device-a", "physical-device-a"),
    ).json()
    second = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("new-device-b", "physical-device-b"),
    ).json()
    assert first["me"]["userId"] != second["me"]["userId"]


def test_blocked_device_cannot_bypass_block_with_new_app_user_id(
    client: TestClient,
) -> None:
    first = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("blocked-owner", "blocked-device"),
    ).json()

    async def block() -> None:
        async with AsyncSessionLocal() as session:
            user = await session.get(User, first["me"]["userId"])
            user.is_blocked = True
            user.token_version += 1
            await session.commit()

    asyncio.run(block())
    restored = client.post(
        "/v1/auth/anonymous",
        json=_anonymous_payload("blocked-reinstall", "blocked-device"),
    )
    assert restored.status_code == 403


def test_concurrent_anonymous_auth_same_device_creates_one_user(tmp_path) -> None:
    async def run_race() -> tuple[list[int], int]:
        database = tmp_path / "anonymous-auth-race.db"
        engine = create_async_engine(
            f"sqlite+aiosqlite:///{database.as_posix()}",
            connect_args={"timeout": 30},
        )
        sessions = async_sessionmaker(engine, expire_on_commit=False)
        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)

            async def authenticate(index: int) -> int:
                async with sessions() as session:
                    user = await resolve_anonymous_user(
                        session,
                        app_user_id=f"concurrent-install-{index}",
                        device_hash="stable-concurrent-device-hash",
                        platform="android",
                    )
                    return user.id

            user_ids = await asyncio.gather(
                authenticate(1),
                authenticate(2),
            )
            async with sessions() as session:
                user_count = await session.scalar(
                    select(func.count(User.id)).where(
                        User.device_hash == "stable-concurrent-device-hash"
                    )
                )
            return user_ids, int(user_count or 0)
        finally:
            await engine.dispose()

    user_ids, user_count = asyncio.run(run_race())
    assert user_ids[0] == user_ids[1]
    assert user_count == 1


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
