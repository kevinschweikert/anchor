import anchor/db
import anchor/sql
import argus
import gleam/bool
import gleam/list
import gleam/result
import shared
import sqlight

pub fn authenticate(
  conn: sqlight.Connection,
  email: String,
  password: String,
) -> Result(shared.User, Nil) {
  use row <- result.try(get_by_email(conn, email) |> result.replace_error(Nil))
  use maybe_verified <- result.try(
    argus.verify(row.password_hash, password) |> result.replace_error(Nil),
  )
  use <- bool.guard(when: maybe_verified == False, return: Error(Nil))
  Ok(shared.User(id: row.id, email: row.email))
}

fn get_by_email(conn: sqlight.Connection, email: String) {
  let #(sql, with, expecting) = sql.get_user_by_email(email)
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:) |> db.expect_one,
  )
  row
}
