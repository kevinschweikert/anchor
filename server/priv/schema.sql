CREATE TABLE IF NOT EXISTS resources(
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL,
    gap_seconds INTEGER NOT NULL,
    currency TEXT NOT NULL,
    allow_animals BOOLEAN NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
