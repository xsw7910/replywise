import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI

from app.api.health import router as health_router
from app.config import settings

logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("ReplyWise backend starting — env=%s", settings.app_env)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="ReplyWise API",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.app_env != "prod" else None,
        redoc_url=None,
    )

    app.include_router(health_router)
    return app


app = create_app()
