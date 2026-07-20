from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class CreditPurchase(Base):
    __tablename__ = "credit_purchases"
    __table_args__ = (
        Index("ix_credit_purchases_user_id", "user_id"),
        # Second idempotency guard: a given RevenueCat purchase resource can back
        # at most one ledger row, regardless of which store id it resolved to.
        Index(
            "uq_credit_purchases_revenuecat_purchase_id",
            "revenuecat_purchase_id",
            unique=True,
        ),
    )

    # Canonical, store-level transaction id shared by every delivery path. For
    # Android this is the Google Play order id (e.g. "GPA.####-####-####-#####").
    transaction_id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    product_id: Mapped[str] = mapped_column(String, nullable=False)
    credits_granted: Mapped[int] = mapped_column(Integer, nullable=False)
    # RevenueCat V2 purchase resource id (e.g. "otpGps..."). Recorded for audit
    # and as a uniqueness guard; NOT used as the canonical grant key because the
    # webhook never carries it.
    revenuecat_purchase_id: Mapped[str | None] = mapped_column(
        String, nullable=True
    )
    # Store ("play_store"/"app_store") and grant source ("webhook"/"sync"),
    # recorded for the audit trail.
    store: Mapped[str | None] = mapped_column(String, nullable=True)
    source: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
