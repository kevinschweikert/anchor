-- name: InsertSession :one
INSERT INTO
sessions(id, user_id, expires_at)
values
($session_id, $user_id, $expires_at)
RETURNING id;

-- name: LookupActiveSession :one
SELECT users.id, users.name, users.email
FROM sessions
JOIN users ON users.id = sessions.user_id
WHERE sessions.id = $session_id AND sessions.expires_at > $now;

-- name: DeleteSession :exec
DELETE FROM
sessions
WHERE
sessions.id = $session_id;

-- name: DeleteExpiredSessions :exec
DELETE FROM
sessions
WHERE
sessions.expires_at <= $now;
