from typing import Literal

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class ApiModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class AudienceRequest(ApiModel):
    mode: Literal["auto", "preset", "custom"] = "auto"
    preset: str | None = None
    custom: str | None = None
    formality: int = Field(default=50, ge=0, le=100)


class ReplyRequest(ApiModel):
    incoming: str
    guidance: str = ""
    guidance_lang: str = "en"
    output_lang: str = "en"
    tone: str | None = None
    audience: AudienceRequest = Field(default_factory=AudienceRequest)


class ReplyVersion(ApiModel):
    label: Literal["Professional", "Friendly", "Short"]
    text: str


class UsageResponse(ApiModel):
    is_premium: bool
    free_uses_limit: int
    free_uses_used: int
    free_uses_left: int | None
    paid_credits: int
    upgrade_required: bool
    credits_used: int = 1
    source: Literal["free", "credit"] | None


class ReplyResponse(ApiModel):
    versions: list[ReplyVersion]
    why: str
    usage: UsageResponse | None = None


class PolishRequest(ApiModel):
    draft: str
    direction: Literal["natural", "professional", "friendly", "concise", "custom"]
    custom: str | None = None
    guidance_lang: str = "en"


class PolishResponse(ApiModel):
    polished: str
    changes: str
    usage: UsageResponse | None = None


class ExplainRequest(ApiModel):
    text: str
    explain_lang: str = "en"


class ExplainResponse(ApiModel):
    meaning: str
    tone: str
    hidden_meaning: str
    suggested_replies: list[str] = Field(min_length=1, max_length=3)
