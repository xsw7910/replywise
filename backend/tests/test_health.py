from fastapi.testclient import TestClient


def test_health_returns_ok(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200


def test_health_response_body(client: TestClient):
    response = client.get("/health")
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "reply-backend"
