import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.ai import router as ai_router
from app.api.v1.me import router as me_router
from app.api.v1.credits import router as credits_router
from app.api.v1.dev import router as dev_router
from app.api.v1.entitlement import router as entitlement_router
from app.api.v1.webhooks import router as webhooks_router
from app.config import settings
from app.database import Base, engine
import app.models.credit  # noqa: F401 — registers CreditPurchase with Base.metadata
import app.models.ad_reward  # noqa: F401 — registers AdReward with Base.metadata
import app.models.device_user_binding  # noqa: F401 — stable device ownership
import app.models.revenuecat_event  # noqa: F401 — registers webhook events
from app.errors import install_error_handlers

logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("ReplyWise backend starting — env=%s", settings.runtime_env)
    if settings.is_dev_or_test:
        async with engine.begin() as conn:
            if "sqlite" in settings.database_url:
                await conn.execute(text("PRAGMA journal_mode=WAL"))
                await conn.execute(text("PRAGMA busy_timeout=10000"))
                await conn.execute(text("PRAGMA synchronous=NORMAL"))
            await conn.run_sync(Base.metadata.create_all)
    else:
        logger.info(
            "Production schema auto-creation is disabled; "
            "database migrations must be applied with Alembic."
        )
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="ReplyWise API",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.runtime_env != "prod" else None,
        redoc_url=None,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(health_router)
    app.include_router(auth_router)
    app.include_router(me_router)
    app.include_router(ai_router)
    app.include_router(entitlement_router)
    app.include_router(credits_router)
    app.include_router(webhooks_router)
    app.include_router(dev_router)
    install_error_handlers(app)
    return app


app = create_app()
