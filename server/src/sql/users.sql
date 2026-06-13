-- name: GetUserByEmail :one
SELECT users.id, users.name, users.email, users.password_hash
FROM users
WHERE users.email = $email;
