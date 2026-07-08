"""Add database-backed app status configs.

Revision ID: 20260707_0005
Revises: 20260706_0004
Create Date: 2026-07-07
"""

from datetime import datetime, timezone
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260707_0005"
down_revision: Union[str, Sequence[str], None] = "20260706_0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "app_status_configs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("app_name", sa.String(), nullable=False),
        sa.Column("platform", sa.String(), nullable=False),
        sa.Column("maintenance_enabled", sa.Boolean(), nullable=False),
        sa.Column("maintenance_message", sa.String(), nullable=False),
        sa.Column("min_supported_version", sa.String(), nullable=False),
        sa.Column("latest_version", sa.String(), nullable=False),
        sa.Column("force_update", sa.Boolean(), nullable=False),
        sa.Column("update_message", sa.String(), nullable=False),
        sa.Column("disabled_features", sa.JSON(), nullable=False),
        sa.Column("support_email", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "app_name",
            "platform",
            name="uq_app_status_configs_app_platform",
        ),
    )
    op.create_index(
        "ix_app_status_configs_app_platform",
        "app_status_configs",
        ["app_name", "platform"],
        unique=False,
    )

    app_status_configs = sa.table(
        "app_status_configs",
        sa.column("app_name", sa.String()),
        sa.column("platform", sa.String()),
        sa.column("maintenance_enabled", sa.Boolean()),
        sa.column("maintenance_message", sa.String()),
        sa.column("min_supported_version", sa.String()),
        sa.column("latest_version", sa.String()),
        sa.column("force_update", sa.Boolean()),
        sa.column("update_message", sa.String()),
        sa.column("disabled_features", sa.JSON()),
        sa.column("support_email", sa.String()),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
    )
    now = datetime.now(timezone.utc)
    op.bulk_insert(
        app_status_configs,
        [
            {
                "app_name": "replywise",
                "platform": "android",
                "maintenance_enabled": False,
                "maintenance_message": (
                    "We are doing maintenance. Please try again later."
                ),
                "min_supported_version": "1.0.0",
                "latest_version": "1.0.0",
                "force_update": False,
                "update_message": (
                    "A new version is available. "
                    "Please update for the best experience."
                ),
                "disabled_features": [],
                "support_email": "support@novaaistudio.ca",
                "created_at": now,
                "updated_at": now,
            }
        ],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_app_status_configs_app_platform",
        table_name="app_status_configs",
    )
    op.drop_table("app_status_configs")
