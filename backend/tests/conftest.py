import os

# run-backend-mock.ps1 / run-backend-dev.ps1 set these env vars in the
# caller's PowerShell session.  When test.ps1 runs in the same session,
# pytest inherits them and they corrupt two things:
#
#   REPLY_ENV=dev   — overrides app_env="prod" kwargs in test-created
#                     Settings instances (reply_env takes precedence in
#                     runtime_env), so production validation never fires.
#
#   DEV_TOOLS_ENABLED=true — makes the module-level settings singleton start
#                            with dev_tools_enabled=True, causing
#                            test_dev_endpoints_are_disabled_by_default to
#                            receive 200 instead of 404.
#
# All three must be neutralised before the first app import because
# Settings() is a module-level singleton built at import time.
os.environ.pop("REPLY_ENV", None)
os.environ["DEV_TOOLS_ENABLED"] = "false"
os.environ["MOCK_AI_ENABLED"] = "false"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture()
def client() -> TestClient:
    with TestClient(app) as c:
        yield c
