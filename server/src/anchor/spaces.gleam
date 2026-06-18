import anchor/db
import anchor/sql
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import shared
import sqlight
import youid/uuid

pub fn list(conn: sqlight.Connection) -> Result(List(shared.Space), db.Error) {
  let #(sql, with, expecting) = sql.all_spaces()
  let with = list.map(with, db.parrot_to_sqlight)
  use rows <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:)
    |> result.map_error(db.DbError),
  )
  use row <- list.map(rows)
  let sql.AllSpaces(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = row
  row_to_space(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  )
}

pub fn get(
  id: String,
  conn: sqlight.Connection,
) -> Result(shared.Space, db.Error) {
  let #(sql, with, expecting) = sql.get_space(id)
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    db.expect_one(sqlight.query(sql, on: conn, with:, expecting:)),
  )
  let sql.GetSpace(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = row
  row_to_space(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  )
}

pub fn create(
  conn: sqlight.Connection,
  new: shared.NewSpace,
) -> Result(shared.Space, db.Error) {
  let shared.NewSpace(name:, capacity:, gap_seconds:, currency:, allow_animals:) =
    new
  let #(sql, with, expecting) =
    sql.create_space(
      id: uuid.v7_string(),
      name:,
      capacity:,
      gap_seconds:,
      currency:,
      allow_animals:,
      created_at: timestamp.system_time(),
    )
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    db.expect_one(sqlight.query(sql, on: conn, with:, expecting:)),
  )
  row_to_space(
    id: row.id,
    name: row.name,
    capacity: row.capacity,
    gap_seconds: row.gap_seconds,
    currency: row.currency,
    allow_animals: row.allow_animals,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn row_to_space(
  id id: String,
  name name: String,
  capacity capacity: Int,
  gap_seconds gap_seconds: Int,
  currency currency: String,
  allow_animals allow_animals: Bool,
  created_at created_at: Timestamp,
  updated_at updated_at: Option(Timestamp),
) -> shared.Space {
  shared.Space(
    id:,
    name:,
    capacity:,
    gap: duration.seconds(gap_seconds),
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
    availability: [],
    pricing: [],
  )
}
