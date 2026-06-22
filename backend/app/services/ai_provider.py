import json
from typing import Protocol


class AIProvider(Protocol):
    async def complete(self, system_prompt: str, payload: dict) -> str: ...


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
                            "label": "Professional",
                            "text": f"Thank you for your message about: {incoming}",
                        },
                        {
                            "label": "Friendly",
                            "text": f"Thanks for letting me know about: {incoming}",
                        },
                        {"label": "Short", "text": "Thanks — that works for me."},
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

