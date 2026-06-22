from datetime import datetime, time, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.errors import ApiException
from app.models.explain_event import ExplainRequestEvent
from app.models.user import User
from app.schemas.ai import (
    ExplainRequest,
    ExplainResponse,
    PolishRequest,
    PolishResponse,
    ReplyRequest,
    ReplyResponse,
)
from app.services.ai_provider import FakeAIProvider
from app.services.ai_service import AIService

router = APIRouter(prefix="/v1", tags=["ai"])

_ai_service = AIService(FakeAIProvider())


def get_ai_service() -> AIService:
    return _ai_service


def _required(value: str, field: str, maximum: int) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise ApiException(
            code="VALIDATION_ERROR",
            message=f"{field} must not be empty",
            status_code=400,
            field=field,
        )
    if len(cleaned) > maximum:
        raise ApiException(
            code="INPUT_TOO_LONG",
            message=f"{field} exceeds {maximum} characters",
            status_code=400,
            field=field,
        )
    _safety_gate(cleaned, field)
    return cleaned


def _optional(value: str | None, field: str, maximum: int) -> str | None:
    if value is None:
        return None
    cleaned = value.strip()
    if len(cleaned) > maximum:
        raise ApiException(
            code="INPUT_TOO_LONG",
            message=f"{field} exceeds {maximum} characters",
            status_code=400,
            field=field,
        )
    if cleaned:
        _safety_gate(cleaned, field)
    return cleaned or None


def _safety_gate(value: str, field: str) -> None:
    if "\x00" in value or any(value.count(char) > 2000 for char in set(value)):
        raise ApiException(
            code="VALIDATION_ERROR",
            message=f"{field} contains unsupported content",
            status_code=400,
            field=field,
        )


@router.post("/reply", response_model=ReplyResponse)
async def reply(
    body: ReplyRequest,
    _: User = Depends(get_current_user),
    service: AIService = Depends(get_ai_service),
) -> ReplyResponse:
    body.incoming = _required(body.incoming, "incoming", 4000)
    body.guidance = _required(body.guidance, "guidance", 1000)
    body.audience.custom = _optional(body.audience.custom, "audience.custom", 500)
    body.output_lang = "en"
    return await service.reply(body)


@router.post("/polish", response_model=PolishResponse)
async def polish(
    body: PolishRequest,
    _: User = Depends(get_current_user),
    service: AIService = Depends(get_ai_service),
) -> PolishResponse:
    body.draft = _required(body.draft, "draft", 4000)
    body.custom = _optional(body.custom, "custom", 500)
    if body.direction == "custom" and not body.custom:
        raise ApiException(
            code="VALIDATION_ERROR",
            message="custom guidance is required for custom direction",
            status_code=400,
            field="custom",
        )
    return await service.polish(body)


@router.post("/explain", response_model=ExplainResponse)
async def explain(
    body: ExplainRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: AIService = Depends(get_ai_service),
) -> ExplainResponse:
    body.text = _required(body.text, "text", 4000)
    day_start = datetime.combine(datetime.now(timezone.utc).date(), time.min, timezone.utc)
    count = await db.scalar(
        select(func.count(ExplainRequestEvent.id)).where(
            ExplainRequestEvent.user_id == current_user.id,
            ExplainRequestEvent.created_at >= day_start,
        )
    )
    if (count or 0) >= settings.explain_daily_limit:
        raise ApiException(
            code="RATE_LIMITED",
            message="Daily Explain limit reached. Please try again tomorrow.",
            status_code=429,
        )

    db.add(ExplainRequestEvent(user_id=current_user.id))
    await db.commit()
    return await service.explain(body)

