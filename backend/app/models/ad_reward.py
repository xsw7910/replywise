from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AdReward(Base):
    """One row per credited rewarded-ad view.

    The (user_id, idempotency_key) unique constraint makes granting idempotent:
    replaying the same client-generated key never adds a second credit. Rows are
    also the source of truth for the per-user daily cap and the inter-reward
    cooldown, both enforced in ``ad_reward_service``.
    """

    __tablename__ = "ad_rewards"
    __table_args__ = (
        UniqueConstraint("user_id", "idempotency_key", name="uq_ad_rewards_user_key"),
        Index("ix_ad_rewards_user_created", "user_id", "created_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    idempotency_key: Mapped[str] = mapped_column(String, nullable=False)
    reward_type: Mapped[str] = mapped_column(String, nullable=False)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
