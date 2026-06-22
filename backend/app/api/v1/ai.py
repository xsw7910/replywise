from datetime import datetime, time, timezone

from fastapi import APIRouter, Depends, Header
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.errors import ApiException
from app.models.usage import UsageEvent
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
from app.services.usage_service import (
    begin_generation,
    canonicalize,
    finish_generation,
    rollback_generation,
)
from app.services.entitlement_service import is_user_premium

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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: AIService = Depends(get_ai_service),
    idempotency_key: str | None = Header(None, alias="X-Idempotency-Key"),
) -> ReplyResponse:
    body.incoming = _required(body.incoming, "incoming", 4000)
    body.guidance = _required(body.guidance, "guidance", 1000)
    body.audience.custom = _optional(body.audience.custom, "audience.custom", 500)
    body.output_lang = "en"
    if not idempotency_key:
        raise ApiException("VALIDATION_ERROR", "X-Idempotency-Key is required", 400)
    _, request_hash = canonicalize(body)
    source, cached = await begin_generation(
        db,
        current_user.id,
        "reply",
        idempotency_key,
        request_hash,
        is_premium=await is_user_premium(db, current_user.id),
    )
    if cached is not None:
        return ReplyResponse.model_validate(cached)
    try:
        result = await service.reply(body)
    except ApiException as error:
        await rollback_generation(db, current_user.id, "reply", idempotency_key, source, error.code)
        raise
    combined = await finish_generation(db, current_user.id, "reply", idempotency_key, source, result.model_dump(mode="json", by_alias=True))
    return ReplyResponse.model_validate(combined)


@router.post("/polish", response_model=PolishResponse)
async def polish(
    body: PolishRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: AIService = Depends(get_ai_service),
    idempotency_key: str | None = Header(None, alias="X-Idempotency-Key"),
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
    if not idempotency_key:
        raise ApiException("VALIDATION_ERROR", "X-Idempotency-Key is required", 400)
    _, request_hash = canonicalize(body)
    source, cached = await begin_generation(
        db,
        current_user.id,
        "polish",
        idempotency_key,
        request_hash,
        is_premium=await is_user_premium(db, current_user.id),
    )
    if cached is not None:
        return PolishResponse.model_validate(cached)
    try:
        result = await service.polish(body)
    except ApiException as error:
        await rollback_generation(db, current_user.id, "polish", idempotency_key, source, error.code)
        raise
    combined = await finish_generation(db, current_user.id, "polish", idempotency_key, source, result.model_dump(mode="json", by_alias=True))
    return PolishResponse.model_validate(combined)


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
        select(func.count(UsageEvent.id)).where(
            UsageEvent.user_id == current_user.id,
            UsageEvent.endpoint == "explain",
            UsageEvent.created_at >= day_start,
        )
    )
    if (count or 0) >= settings.explain_daily_limit:
        raise ApiException(
            code="RATE_LIMITED",
            message="Daily Explain limit reached. Please try again tomorrow.",
            status_code=429,
        )

    try:
        result = await service.explain(body)
        db.add(UsageEvent(user_id=current_user.id, endpoint="explain", credits_used=0, source="explain", prompt_version="explain_v1", success=True))
        await db.commit()
        return result
    except ApiException as error:
        db.add(UsageEvent(user_id=current_user.id, endpoint="explain", credits_used=0, source="explain", prompt_version="explain_v1", success=False, error_code=error.code))
        await db.commit()
        raise
