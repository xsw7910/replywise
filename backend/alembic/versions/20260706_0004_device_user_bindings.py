"""Add stable device-to-user bindings for anonymous account restoration.

Revision ID: 20260706_0004
Revises: 20260705_0003
Create Date: 2026-07-06
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260706_0004"
down_revision: Union[str, Sequence[str], None] = "20260705_0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "device_user_bindings",
        sa.Column("device_hash", sa.String(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("device_hash"),
        sa.UniqueConstraint("user_id"),
    )

    # Existing installations may already have duplicate user rows for one
    # device. Bind to the oldest row, which is the pre-reinstall account and
    # therefore the identity used for its RevenueCat purchases and paid-credit
    # balance. Duplicate rows are left intact for audit/history; all future
    # anonymous auth for that device resolves through this canonical binding.
    op.execute(
        sa.text(
            """
            INSERT INTO device_user_bindings (device_hash, user_id, created_at)
            SELECT users.device_hash, MIN(users.id), CURRENT_TIMESTAMP
            FROM users
            GROUP BY users.device_hash
            """
        )
    )


def downgrade() -> None:
    op.drop_table("device_user_bindings")

