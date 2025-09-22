CREATE TABLE IF NOT EXISTS rewards_ledger (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  points NUMERIC(18,4) NOT NULL,
  posting_ref TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
