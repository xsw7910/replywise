SUPPORTED_OUTPUT_LANGUAGES: dict[str, str] = {
    "en": "English",
    "zh": "Simplified Chinese",
    "zh_Hant": "Traditional Chinese",
    "es": "Spanish",
    "fr": "French",
    "pt": "Portuguese",
    "de": "German",
    "ja": "Japanese",
    "ko": "Korean",
    "hi": "Hindi",
    "ar": "Arabic",
    "it": "Italian",
    "id": "Indonesian",
    "vi": "Vietnamese",
    "th": "Thai",
    "tr": "Turkish",
    "nl": "Dutch",
    "pl": "Polish",
    "ru": "Russian",
    "uk": "Ukrainian",
}


def normalize_app_locale(value: str | None) -> tuple[str, str]:
    """Return a supported locale code and readable model language name."""
    if not value:
        return "en", SUPPORTED_OUTPUT_LANGUAGES["en"]

    normalized = value.strip().replace("-", "_")
    if not normalized or normalized.lower() in {"system", "default"}:
        return "en", SUPPORTED_OUTPUT_LANGUAGES["en"]

    lowered = normalized.lower()
    if lowered.startswith("zh"):
        is_traditional = (
            "hant" in lowered
            or lowered.endswith("_tw")
            or lowered.endswith("_hk")
            or lowered.endswith("_mo")
        )
        code = "zh_Hant" if is_traditional else "zh"
        return code, SUPPORTED_OUTPUT_LANGUAGES[code]

    base_code = lowered.split("_", maxsplit=1)[0]
    if base_code not in SUPPORTED_OUTPUT_LANGUAGES:
        return "en", SUPPORTED_OUTPUT_LANGUAGES["en"]
    return base_code, SUPPORTED_OUTPUT_LANGUAGES[base_code]
