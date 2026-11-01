CREATE TABLE IF NOT EXISTS online_users (
  username TEXT PRIMARY KEY REFERENCES registered_users(username) ON DELETE CASCADE,
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS online_users_last_seen_idx
  ON online_users (last_seen);
