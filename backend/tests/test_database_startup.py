import pytest

from app import main


@pytest.mark.asyncio
async def test_production_lifespan_never_auto_creates_schema(monkeypatch) -> None:
    class _EngineThatMustNotBeUsed:
        def begin(self):
            raise AssertionError(
                "Production startup must not open a create_all transaction"
            )

    monkeypatch.setattr(main.settings, "reply_env", "prod")
    monkeypatch.setattr(main, "engine", _EngineThatMustNotBeUsed())

    async with main.lifespan(main.app):
        pass
