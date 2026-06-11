import anchor/db
import anchor/sql
import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import shared.{type User}
import sqlight
import youid/uuid

pub fn lookup_active(
  conn: sqlight.Connection,
  sid: String,
) -> Result(User, db.Error) {
  let #(sql, with, expecting) =
    sql.lookup_active_session(sid, timestamp.system_time())
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:) |> db.expect_one,
  )
  row_to_user(row.id, row.email, row.password_hash)
}

pub fn insert(
  conn: sqlight.Connection,
  sid: String,
  user_id: String,
  ttl: Int,
) -> Result(String, db.Error) {
  let expires_at =
    timestamp.system_time() |> timestamp.add(duration.seconds(ttl))
  let #(sql, with, expecting) = sql.insert_session(sid, user_id, expires_at)
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:) |> db.expect_one,
  )
  row.id
}

pub fn delete(
  conn: sqlight.Connection,
  sid: String,
) -> Result(Nil, sqlight.Error) {
  let #(sql, with) = sql.delete_session(sid)
  let with = list.map(with, db.parrot_to_sqlight)
  use _row <- result.map(sqlight.query(
    sql,
    on: conn,
    with:,
    expecting: decode.success(Nil),
  ))
  Nil
}

pub fn delete_expired(conn: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  let #(sql, with) = sql.delete_expired_sessions(timestamp.system_time())
  let with = list.map(with, db.parrot_to_sqlight)
  use _row <- result.map(sqlight.query(
    sql,
    on: conn,
    with:,
    expecting: decode.success(Nil),
  ))
  Nil
}

fn row_to_user(id: String, email: String, password_hash: String) -> User {
  let assert Ok(uuid) = uuid.from_string(id)
  shared.User(id: uuid, email:, password_hash:)
}
