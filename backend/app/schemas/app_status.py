from datetime import datetime

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class AppStatusResponse(BaseModel):
    """Remote-config payload returned by ``GET /v1/app-status``.

    Serialized with camelCase aliases (FastAPI defaults ``by_alias=True``) so
    the wire contract is ``appName``, ``minSupportedVersion``, etc.
    """

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    app_name: str
    platform: str
    maintenance: bool
    maintenance_message: str
    min_supported_version: str
    min_supported_build_number: int
    latest_version: str
    latest_build_number: int
    force_update: bool
    update_message: str
    disabled_features: list[str]
    support_email: str
    updated_at: datetime
