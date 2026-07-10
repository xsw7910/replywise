"""Add build-number columns to app_status_configs.

Two Android builds can share a version name (1.0.0+32 vs 1.0.0+33), so update
checks also need the numeric build number.

Revision ID: 20260710_0006
Revises: 20260707_0005
Create Date: 2026-07-10
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260710_0006"
down_revision: Union[str, Sequence[str], None] = "20260707_0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Current Android build number (pubspec `version: 1.0.0+33`).
CURRENT_ANDROID_BUILD_NUMBER = 33


def upgrade() -> None:
    op.add_column(
        "app_status_configs",
        sa.Column(
            "min_supported_build_number",
            sa.Integer(),
            nullable=False,
            server_default=str(CURRENT_ANDROID_BUILD_NUMBER),
        ),
    )
    op.add_column(
        "app_status_configs",
        sa.Column(
            "latest_build_number",
            sa.Integer(),
            nullable=False,
            server_default=str(CURRENT_ANDROID_BUILD_NUMBER),
        ),
    )


def downgrade() -> None:
    op.drop_column("app_status_configs", "latest_build_number")
    op.drop_column("app_status_configs", "min_supported_build_number")
