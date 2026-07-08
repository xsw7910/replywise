from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Index, Integer, JSON, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AppStatusConfig(Base):
    """Database-backed app status / remote config for one app + platform."""

    __tablename__ = "app_status_configs"
    __table_args__ = (
        UniqueConstraint(
            "app_name",
            "platform",
            name="uq_app_status_configs_app_platform",
        ),
        Index("ix_app_status_configs_app_platform", "app_name", "platform"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    app_name: Mapped[str] = mapped_column(String, nullable=False)
    platform: Mapped[str] = mapped_column(String, nullable=False)
    maintenance_enabled: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )
    maintenance_message: Mapped[str] = mapped_column(String, nullable=False)
    min_supported_version: Mapped[str] = mapped_column(String, nullable=False)
    latest_version: Mapped[str] = mapped_column(String, nullable=False)
    force_update: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    update_message: Mapped[str] = mapped_column(String, nullable=False)
    disabled_features: Mapped[list[str]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
    )
    support_email: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
