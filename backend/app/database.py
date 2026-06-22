from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

_is_sqlite = "sqlite" in settings.database_url
_is_memory = ":memory:" in settings.database_url

_connect_args: dict = {}
_engine_kwargs: dict = {}

if _is_sqlite:
    _connect_args["check_same_thread"] = False
    if _is_memory:
        from sqlalchemy.pool import StaticPool
        _engine_kwargs["poolclass"] = StaticPool

engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args=_connect_args,
    **_engine_kwargs,
)

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:  # type: ignore[override]
    async with AsyncSessionLocal() as session:
        yield session
