The argon2 encoded hash already embeds the algorithm, params, and per-password salt — you only store one column, no separate salt field.

Hashing (signup / admin seed):

import argus

let assert Ok(hashes) =
argus.hasher() // OWASP defaults, Argon2id
|> argus.hash(password, salt) // salt = 16 random bytes
// store hashes.encoded_hash in users.password_hash

argus.hash/3 needs a salt you supply — generate with crypto:strong_rand_bytes(16) via a tiny FFI shim, since there's no helper in argus itself. Same shim doubles for generating session IDs.

Login:

let assert Ok(Some(user)) = users.get_by_email(ctx.conn, email)
case argus.verify(user.password_hash, password) {
Ok(True) -> {
let session_id = random_token(32) // base64url of 32 random bytes
let assert Ok(_) = sessions.insert(ctx.conn, session_id, user.id, ttl: 30 * 86400)
wisp.redirect("/admin")
|> wisp.set_cookie(req, "sid", session_id, wisp.Signed, 30 * 86400)
}
_ -> wisp.redirect("/login?error=1")
}

Middleware (gates /admin/*):

pub fn require_admin(req, ctx, handler) {
case wisp.get_cookie(req, "sid", wisp.Signed) {
Ok(sid) ->
case sessions.lookup_active(ctx.conn, sid) {
Ok(Some(user)) -> handler(Context(..ctx, user: Some(user)))
_ -> wisp.redirect("/login")
}
_ -> wisp.redirect("/login")
}
}

sessions.lookup_active does SELECT users.* FROM sessions JOIN users ... WHERE sessions.id = ? AND expires_at > unixepoch() — one query, gives you the user object.

Logout: DELETE FROM sessions WHERE id = ? + overwrite the cookie with empty value and max_age=0.

Why signed cookie when the session ID is already random? Defense in depth — wisp.Signed uses your secret key base so a tampered cookie is rejected before it ever hits the DB. Costs nothing since wisp
does it for you.

Housekeeping: a cron-ish task to DELETE FROM sessions WHERE expires_at < unixepoch() every so often. For a self-hosted single-admin app you can also just run it lazily on each lookup or skip it — old
sessions are harmless once expired.
