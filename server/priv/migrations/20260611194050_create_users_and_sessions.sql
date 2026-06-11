-- migrate:up

CREATE TABLE IF NOT EXISTS users(
    id TEXT PRIMARY KEY CHECK (id = LOWER(id)),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions(
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    expires_at TIMESTAMP NOT NULL
);

-- migrate:down
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;

