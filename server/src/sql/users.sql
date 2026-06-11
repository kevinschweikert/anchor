-- name: GetUserByEmail :one
SELECT *
FROM users
WHERE users.email = $email;
