"""Add RevenueCat/store identifier + audit columns to credit_purchases.

Consumable credit grants were doubled because the webhook keyed the ledger on
the Google Play order id (``GPA.…``) while ``/v1/credits/sync`` keyed it on the
RevenueCat V2 purchase resource id (``otpGps…``). The canonical key is now
always the store transaction id; these additive columns record the RevenueCat
purchase id (with a uniqueness guard) and the delivery source for auditing.

This migration is purely additive and backward compatible:
  * existing rows keep their ``transaction_id`` primary key unchanged;
  * new columns are nullable and default to NULL for historical rows;
  * NO financial rows are read, modified, or deleted. Historical duplicates are
    left intact for a separate, reviewed remediation (see the audit query in
    the incident report).

The unique index on ``revenuecat_purchase_id`` is safe to add because every
existing row has NULL there, and both PostgreSQL and SQLite permit multiple
NULLs in a unique index.

Revision ID: 20260720_0007
Revises: 20260710_0006
Create Date: 2026-07-20
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260720_0007"
down_revision: Union[str, Sequence[str], None] = "20260710_0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "credit_purchases",
        sa.Column("revenuecat_purchase_id", sa.String(), nullable=True),
    )
    op.add_column(
        "credit_purchases",
        sa.Column("store", sa.String(), nullable=True),
    )
    op.add_column(
        "credit_purchases",
        sa.Column("source", sa.String(), nullable=True),
    )
    op.create_index(
        "uq_credit_purchases_revenuecat_purchase_id",
        "credit_purchases",
        ["revenuecat_purchase_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        "uq_credit_purchases_revenuecat_purchase_id",
        table_name="credit_purchases",
    )
    op.drop_column("credit_purchases", "source")
    op.drop_column("credit_purchases", "store")
    op.drop_column("credit_purchases", "revenuecat_purchase_id")
