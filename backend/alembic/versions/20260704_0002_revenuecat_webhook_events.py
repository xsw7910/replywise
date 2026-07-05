"""Add idempotent RevenueCat webhook event storage.

Revision ID: 20260704_0002
Revises: 20260704_0001
Create Date: 2026-07-04
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260704_0002"
down_revision: Union[str, Sequence[str], None] = "20260704_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "revenuecat_events",
        sa.Column("event_id", sa.String(), nullable=False),
        sa.Column("app_user_id", sa.String(), nullable=False),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("product_id", sa.String(), nullable=True),
        sa.Column("transaction_id", sa.String(), nullable=True),
        sa.Column("raw_event_hash", sa.String(length=64), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("event_id"),
    )
    op.create_index(
        "ix_revenuecat_events_app_user_id",
        "revenuecat_events",
        ["app_user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_revenuecat_events_app_user_id",
        table_name="revenuecat_events",
    )
    op.drop_table("revenuecat_events")
