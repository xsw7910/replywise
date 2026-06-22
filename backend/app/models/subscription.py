from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class SubscriptionCache(Base):
    __tablename__ = "subscription_cache"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), primary_key=True)
    entitlement_id: Mapped[str] = mapped_column(String, nullable=False)
    is_premium: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    product_identifier: Mapped[str | None] = mapped_column(String, nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    verified_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
