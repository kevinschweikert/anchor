-- migrate:up

-- TIMESTAMP columns store unix MICROSECONDS (parrot's dev.datetime_decoder and
-- db.parrot_to_sqlight both use the pog convention), not unixepoch() seconds.
CREATE TABLE IF NOT EXISTS resources(
    id TEXT PRIMARY KEY CHECK (id = LOWER(id)),
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL,
    gap_seconds INTEGER NOT NULL,
    currency TEXT NOT NULL,
    allow_animals BOOLEAN NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

-- migrate:down

DROP TABLE IF EXISTS resources;
