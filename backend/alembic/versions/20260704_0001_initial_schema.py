"""Create the initial ReplyWise schema.

Revision ID: 20260704_0001
Revises:
Create Date: 2026-07-04
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260704_0001"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "device_usage",
        sa.Column("device_hash", sa.String(), nullable=False),
        sa.Column("free_uses_limit", sa.Integer(), nullable=False),
        sa.Column("free_uses_used", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("device_hash"),
    )
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("app_user_id", sa.String(), nullable=False),
        sa.Column("device_hash", sa.String(), nullable=False),
        sa.Column("platform", sa.String(), nullable=False),
        sa.Column("token_version", sa.Integer(), nullable=False),
        sa.Column("is_blocked", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_app_user_id", "users", ["app_user_id"], unique=True)
    op.create_index("ix_users_id", "users", ["id"], unique=False)

    op.create_table(
        "credit_purchases",
        sa.Column("transaction_id", sa.String(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("product_id", sa.String(), nullable=False),
        sa.Column("credits_granted", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("transaction_id"),
    )
    op.create_index(
        "ix_credit_purchases_user_id",
        "credit_purchases",
        ["user_id"],
        unique=False,
    )
    op.create_table(
        "explain_request_events",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_explain_request_events_created_at",
        "explain_request_events",
        ["created_at"],
        unique=False,
    )
    op.create_index(
        "ix_explain_request_events_user_id",
        "explain_request_events",
        ["user_id"],
        unique=False,
    )
    op.create_table(
        "idempotency_keys",
        sa.Column("key", sa.String(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("endpoint", sa.String(), nullable=False),
        sa.Column("request_hash", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("source", sa.String(), nullable=True),
        sa.Column("response_json", sa.Text(), nullable=True),
        sa.Column("error_code", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("key"),
    )
    op.create_table(
        "subscription_cache",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("entitlement_id", sa.String(), nullable=False),
        sa.Column("is_premium", sa.Boolean(), nullable=False),
        sa.Column("product_identifier", sa.String(), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("user_id"),
    )
    op.create_table(
        "usage_events",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("endpoint", sa.String(), nullable=False),
        sa.Column("model", sa.String(), nullable=False),
        sa.Column("credits_used", sa.Integer(), nullable=False),
        sa.Column("source", sa.String(), nullable=True),
        sa.Column("prompt_version", sa.String(), nullable=True),
        sa.Column("input_tokens", sa.Integer(), nullable=True),
        sa.Column("output_tokens", sa.Integer(), nullable=True),
        sa.Column("cost_usd", sa.Float(), nullable=True),
        sa.Column("cache_hit", sa.Boolean(), nullable=False),
        sa.Column("success", sa.Boolean(), nullable=False),
        sa.Column("error_code", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_usage_user_endpoint_time",
        "usage_events",
        ["user_id", "endpoint", "created_at"],
        unique=False,
    )
    op.create_table(
        "usage_summary",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("free_uses_limit", sa.Integer(), nullable=False),
        sa.Column("free_uses_used", sa.Integer(), nullable=False),
        sa.Column("paid_credits", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("user_id"),
    )


def downgrade() -> None:
    op.drop_table("usage_summary")
    op.drop_index("ix_usage_user_endpoint_time", table_name="usage_events")
    op.drop_table("usage_events")
    op.drop_table("subscription_cache")
    op.drop_table("idempotency_keys")
    op.drop_index(
        "ix_explain_request_events_user_id",
        table_name="explain_request_events",
    )
    op.drop_index(
        "ix_explain_request_events_created_at",
        table_name="explain_request_events",
    )
    op.drop_table("explain_request_events")
    op.drop_index(
        "ix_credit_purchases_user_id",
        table_name="credit_purchases",
    )
    op.drop_table("credit_purchases")
    op.drop_index("ix_users_id", table_name="users")
    op.drop_index("ix_users_app_user_id", table_name="users")
    op.drop_table("users")
    op.drop_table("device_usage")
