import json
from typing import Protocol

from openai import (
    APIConnectionError,
    APITimeoutError,
    AsyncOpenAI,
    AuthenticationError,
    BadRequestError,
    OpenAIError,
    PermissionDeniedError,
    RateLimitError,
)


class AIProvider(Protocol):
    async def complete(self, system_prompt: str, payload: dict) -> str: ...


class AIProviderError(Exception):
    """Sanitized provider failure safe to map into the public API."""

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int,
        *,
        retryable: bool = False,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
        self.retryable = retryable


class FakeAIProvider:
    """Deterministic local provider for development and tests."""

    async def complete(self, system_prompt: str, payload: dict) -> str:
        task = payload["task"]
        if task == "reply":
            incoming = payload["incoming"]
            return json.dumps(
                {
                    "versions": [
                        {
                            "label": "Formal",
                            "text": f"Thank you for your message about: {incoming}",
                        },
                        {
                            "label": "Casual",
                            "text": f"Thanks for letting me know about: {incoming}",
                        },
                        {"label": "Concise", "text": "Thanks — that works for me."},
                    ],
                    "why": "The wording is clear, natural, and appropriate for the audience.",
                }
            )
        if task == "polish":
            return json.dumps(
                {
                    "polished": payload["draft"].strip(),
                    "changes": "Grammar and tone were refined while preserving the meaning.",
                }
            )
        return json.dumps(
            {
                "meaning": "The message communicates its request directly.",
                "tone": "Neutral and conversational.",
                "hiddenMeaning": "There is no strong hidden meaning.",
                "suggestedReplies": [
                    "Thanks for letting me know.",
                    "Understood — I’ll get back to you shortly.",
                ],
            }
        )


class LocalMockAIProvider(FakeAIProvider):
    """Explicit provider selected by MOCK_AI_ENABLED for local emulator testing."""


class OpenAIProvider:
    """Production provider — calls OpenAI chat completions. Reuse across requests."""

    def __init__(
        self,
        api_key: str,
        model: str = "gpt-4o-mini",
        timeout_seconds: int = 30,
    ) -> None:
        self._client = AsyncOpenAI(
            api_key=api_key,
            timeout=timeout_seconds,
            max_retries=0,
        )
        self._model = model

    async def complete(self, system_prompt: str, payload: dict) -> str:
        try:
            response = await self._client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": json.dumps(payload)},
                ],
                temperature=0.7,
                response_format={"type": "json_object"},
            )
        except (APITimeoutError, APIConnectionError) as error:
            raise AIProviderError(
                "MODEL_UNAVAILABLE",
                "The AI service is temporarily unavailable. Please retry.",
                503,
                retryable=True,
            ) from error
        except RateLimitError as error:
            raise AIProviderError(
                "MODEL_RATE_LIMITED",
                "The AI service is busy right now. Please retry shortly.",
                503,
            ) from error
        except (AuthenticationError, PermissionDeniedError) as error:
            raise AIProviderError(
                "MODEL_CONFIGURATION_ERROR",
                "The AI service is temporarily unavailable.",
                503,
            ) from error
        except BadRequestError as error:
            raise AIProviderError(
                "MODEL_REQUEST_REJECTED",
                "The AI service could not process this request.",
                502,
            ) from error
        except OpenAIError as error:
            raise AIProviderError(
                "MODEL_UNAVAILABLE",
                "The AI service is temporarily unavailable. Please retry.",
                503,
            ) from error
        return response.choices[0].message.content or ""

