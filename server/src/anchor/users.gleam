import anchor/db
import anchor/sql
import gleam/list
import gleam/result
import shared
import sqlight
import youid/uuid

pub fn get_by_email(
  conn: sqlight.Connection,
  email: String,
) -> Result(shared.User, db.Error) {
  let #(sql, with, expecting) = sql.get_user_by_email(email)
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:) |> db.expect_one,
  )
  row_to_user(row.id, row.email, row.password_hash)
}

fn row_to_user(
  id: String,
  email: String,
  password_hash: String,
) -> shared.User {
  let assert Ok(uuid) = uuid.from_string(id)
  shared.User(id: uuid, email:, password_hash:)
}
