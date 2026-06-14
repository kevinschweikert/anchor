-- name: AllSpaces :many
SELECT *
FROM spaces
LIMIT 10;

-- name: GetSpace :one
SELECT *
FROM spaces
WHERE spaces.id == $id COLLATE NOCASE;

-- name: CreateSpace :one
INSERT INTO
spaces(id, name, capacity, gap_seconds, currency, allow_animals, created_at)
VALUES
(?, ?, ?, ?, ?, ?, ?)
RETURNING *;
