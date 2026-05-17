-- name: AllResources :many
SELECT *
FROM resources
LIMIT 10;

-- name: CreateResource :one
INSERT INTO
resources(id, name, capacity, gap_seconds, currency, allow_animals, created_at)
VALUES
(?, ?, ?, ?, ?, ?, ?)
RETURNING *;
