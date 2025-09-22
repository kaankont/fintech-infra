from alembic import op
import sqlalchemy as sa

revision = "0001_init"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "accounts",
        sa.Column("id", sa.BigInteger, primary_key=True),
        sa.Column("owner_id", sa.Text, nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"))
    )
    op.create_table(
        "postings",
        sa.Column("id", sa.BigInteger, primary_key=True),
        sa.Column("debit_account", sa.BigInteger, nullable=False),
        sa.Column("credit_account", sa.BigInteger, nullable=False),
        sa.Column("amount", sa.Numeric(18,2), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("ref", sa.Text),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"))
    )

def downgrade():
    op.drop_table("postings")
    op.drop_table("accounts")
