-- name: AllResources :many
SELECT *
FROM resources
LIMIT 10;

-- name: GetResource :one
SELECT *
FROM resources AS r
WHERE r.id == $id COLLATE NOCASE;

-- name: CreateResource :one
INSERT INTO
resources(id, name, capacity, gap_seconds, currency, allow_animals, created_at)
VALUES
(?, ?, ?, ?, ?, ?, ?)
RETURNING *;
