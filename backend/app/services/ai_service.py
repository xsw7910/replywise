import json

from pydantic import ValidationError

from app.errors import ApiException
from app.locales import normalize_app_locale
from app.prompts import EXPLAIN_SYSTEM_PROMPT, POLISH_SYSTEM_PROMPT, REPLY_SYSTEM_PROMPT
from app.schemas.ai import (
    ExplainRequest,
    ExplainResponse,
    PolishRequest,
    PolishResponse,
    ReplyRequest,
    ReplyResponse,
)
from app.services.ai_provider import AIProvider, AIProviderError

# App/UI-locale fields removed from the model payload so the interface language
# is never seen as an output-language instruction. The interface language is
# re-added only as the clearly scoped ``explanation_language``.
_APP_LANGUAGE_PAYLOAD_FIELDS = (
    "output_lang",
    "guidance_lang",
    "app_locale",
    "explain_lang",
)


class AIService:
    def __init__(self, provider: AIProvider):
        self.provider = provider

    async def reply(self, request: ReplyRequest) -> ReplyResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "reply"
        prompt = self._localized_prompt(
            REPLY_SYSTEM_PROMPT,
            payload,
            request.app_locale,
        )
        return await self._generate(prompt, payload, ReplyResponse)

    async def polish(self, request: PolishRequest) -> PolishResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "polish"
        prompt = self._localized_prompt(
            POLISH_SYSTEM_PROMPT,
            payload,
            request.app_locale,
        )
        return await self._generate(prompt, payload, PolishResponse)

    async def explain(self, request: ExplainRequest) -> ExplainResponse:
        payload = request.model_dump(mode="json")
        payload["task"] = "explain"
        prompt = self._localized_prompt(
            EXPLAIN_SYSTEM_PROMPT,
            payload,
            request.app_locale,
        )
        return await self._generate(prompt, payload, ExplainResponse)

    @staticmethod
    def _localized_prompt(
        system_prompt: str,
        payload: dict,
        app_locale: str | None,
    ) -> str:
        _, explanation_language = normalize_app_locale(app_locale)
        # Strip every app/UI-locale field from the model payload so the
        # interface language can never be read as the requested output
        # language. The UI language is re-introduced ONLY as the clearly named
        # explanation_language, which the prompt scopes to explanation fields.
        for field in _APP_LANGUAGE_PAYLOAD_FIELDS:
            payload.pop(field, None)
        payload["explanation_language"] = explanation_language
        return (
            f"{system_prompt}\n\n"
            f"explanation_language = {explanation_language}.\n"
            "explanation_language is the app interface / UI language. It "
            "governs ONLY the explanation fields (why, changes, meaning, tone, "
            "hiddenMeaning) and their section headings — write those in "
            "explanation_language. "
            "Do not translate JSON keys or fixed enum labels. "
            "The main user-facing content (reply versions, polished text) must "
            "follow the source-text language rules of the task and must NEVER "
            f"be translated into {explanation_language} because of the app "
            "language setting."
        )

    async def _generate(self, system_prompt: str, payload: dict, response_type):
        prompt = system_prompt
        for attempt in range(2):
            try:
                raw = await self.provider.complete(prompt, payload)
            except AIProviderError as error:
                if error.retryable and attempt == 0:
                    continue
                raise ApiException(
                    code=error.code,
                    message=error.message,
                    status_code=error.status_code,
                ) from error
            except Exception as error:
                if attempt == 0:
                    continue
                raise ApiException(
                    code="MODEL_UNAVAILABLE",
                    message="The AI service is temporarily unavailable. Please retry.",
                    status_code=503,
                ) from error
            try:
                stripped = _strip_json_fence(raw)
                try:
                    parsed = json.loads(stripped)
                except json.JSONDecodeError:
                    # Model wrapped JSON in prose despite instructions; extract it.
                    parsed = json.loads(_extract_json_object(stripped))
                if response_type is ReplyResponse:
                    _normalize_legacy_reply_labels(parsed)
                result = response_type.model_validate(parsed)
                _validate_response_shape(result)
                return result
            except (json.JSONDecodeError, ValidationError, ValueError):
                if attempt == 0:
                    prompt = (
                        f"{system_prompt}\n"
                        "Return valid JSON only. Do not add any prose, markdown, or explanation."
                    )

        raise ApiException(
            code="MODEL_PARSE_ERROR",
            message="The AI response could not be parsed. Please retry.",
            status_code=502,
        )


# Reply version labels were renamed; the model may still emit the old ones.
_LEGACY_REPLY_LABELS = {
    "Professional": "Formal",
    "Friendly": "Casual",
    "Short": "Concise",
}


def _normalize_legacy_reply_labels(parsed: object) -> None:
    """Map legacy reply version labels to the current ones, in place."""
    if not isinstance(parsed, dict):
        return
    versions = parsed.get("versions")
    if not isinstance(versions, list):
        return
    for version in versions:
        if isinstance(version, dict):
            label = version.get("label")
            if label in _LEGACY_REPLY_LABELS:
                version["label"] = _LEGACY_REPLY_LABELS[label]


def _strip_json_fence(value: str) -> str:
    """Remove a leading/trailing markdown code fence if present."""
    stripped = value.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        stripped = "\n".join(lines).strip()
    return stripped


def _extract_json_object(text: str) -> str:
    """Find and return the first balanced {...} block in *text*.

    Handles models that add prose before or after the JSON object despite
    instructions to return JSON only. Uses a character walk so nested objects
    and string literals containing braces are handled correctly.

    Raises ValueError when no complete object is found.
    """
    start = text.find("{")
    if start == -1:
        raise ValueError("No JSON object found in provider response")
    depth = 0
    in_string = False
    escape_next = False
    for i in range(start, len(text)):
        ch = text[i]
        if escape_next:
            escape_next = False
            continue
        if ch == "\\" and in_string:
            escape_next = True
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    raise ValueError("No complete JSON object found in provider response")


def _validate_response_shape(result) -> None:
    if isinstance(result, ReplyResponse):
        labels = [version.label for version in result.versions]
        if labels != ["Formal", "Casual", "Concise"]:
            raise ValueError("Reply must contain exactly three ordered versions")
