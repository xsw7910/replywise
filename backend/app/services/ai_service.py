import json

from pydantic import ValidationError

from app.errors import ApiException
from app.prompts import EXPLAIN_SYSTEM_PROMPT, POLISH_SYSTEM_PROMPT, REPLY_SYSTEM_PROMPT
from app.schemas.ai import (
    ExplainRequest,
    ExplainResponse,
    PolishRequest,
    PolishResponse,
    ReplyRequest,
    ReplyResponse,
)
from app.services.ai_provider import AIProvider


class AIService:
    def __init__(self, provider: AIProvider):
        self.provider = provider

    async def reply(self, request: ReplyRequest) -> ReplyResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "reply"
        payload["output_lang"] = "en"
        return await self._generate(REPLY_SYSTEM_PROMPT, payload, ReplyResponse)

    async def polish(self, request: PolishRequest) -> PolishResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "polish"
        return await self._generate(POLISH_SYSTEM_PROMPT, payload, PolishResponse)

    async def explain(self, request: ExplainRequest) -> ExplainResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "explain"
        return await self._generate(EXPLAIN_SYSTEM_PROMPT, payload, ExplainResponse)

    async def _generate(self, system_prompt: str, payload: dict, response_type):
        prompt = system_prompt
        for attempt in range(2):
            try:
                raw = await self.provider.complete(prompt, payload)
            except Exception as error:
                if attempt == 0:
                    continue
                raise ApiException(
                    code="MODEL_UNAVAILABLE",
                    message="The AI service is temporarily unavailable. Please retry.",
                    status_code=503,
                ) from error
            try:
                parsed = json.loads(_strip_json_fence(raw))
                result = response_type.model_validate(parsed)
                _validate_response_shape(result)
                return result
            except (json.JSONDecodeError, ValidationError, ValueError):
                if attempt == 0:
                    prompt = f"{system_prompt}\nReturn valid JSON only."

        raise ApiException(
            code="MODEL_PARSE_ERROR",
            message="The AI response could not be parsed. Please retry.",
            status_code=502,
        )


def _strip_json_fence(value: str) -> str:
    stripped = value.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        stripped = "\n".join(lines).strip()
    return stripped


def _validate_response_shape(result) -> None:
    if isinstance(result, ReplyResponse):
        labels = [version.label for version in result.versions]
        if labels != ["Professional", "Friendly", "Short"]:
            raise ValueError("Reply must contain exactly three ordered versions")
