-- accounts and postings (double-entry)
CREATE TABLE IF NOT EXISTS accounts (
  id BIGSERIAL PRIMARY KEY,
  owner_id TEXT NOT NULL,
  currency CHAR(3) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS postings (
  id BIGSERIAL PRIMARY KEY,
  debit_account BIGINT NOT NULL REFERENCES accounts(id),
  credit_account BIGINT NOT NULL REFERENCES accounts(id),
  amount NUMERIC(18,2) NOT NULL,
  currency CHAR(3) NOT NULL,
  ref TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
