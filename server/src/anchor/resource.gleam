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

pub type Error {
  DbError(sqlight.Error)
  ExpectedOnlyOne
}

pub fn list_resources(
  conn: sqlight.Connection,
) -> Result(List(shared.Resource), Error) {
  let #(sql, with, expecting) = sql.all_resources()
  let with = list.map(with, db.parrot_to_sqlight)
  use rows <- result.map(
    sqlight.query(sql, on: conn, with:, expecting:)
    |> result.map_error(DbError),
  )
  use row <- list.map(rows)
  let sql.AllResources(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = row
  row_to_resource(
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

pub fn get_resource(
  id: String,
  conn: sqlight.Connection,
) -> Result(shared.Resource, Error) {
  let #(sql, with, expecting) = sql.get_resource(id)
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    expect_one(sqlight.query(sql, on: conn, with:, expecting:)),
  )
  let sql.GetResource(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = row
  row_to_resource(
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

pub fn create_resource(
  id id: String,
  name name: String,
  capacity capacity: Int,
  gap_seconds gap_seconds: Int,
  currency currency: String,
  allow_animals allow_animals: Bool,
  conn conn: sqlight.Connection,
) -> Result(shared.Resource, Error) {
  let #(sql, with, expecting) =
    sql.create_resource(
      id:,
      name:,
      capacity:,
      gap_seconds:,
      currency:,
      allow_animals:,
      created_at: timestamp.system_time(),
    )
  let with = list.map(with, db.parrot_to_sqlight)
  use row <- result.map(
    expect_one(sqlight.query(sql, on: conn, with:, expecting:)),
  )
  let sql.CreateResource(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = row
  row_to_resource(
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

fn expect_one(rows: Result(List(a), sqlight.Error)) -> Result(a, Error) {
  case rows {
    Ok([row]) -> Ok(row)
    Ok(_) -> Error(ExpectedOnlyOne)
    Error(err) -> Error(DbError(err))
  }
}

fn row_to_resource(
  id id: String,
  name name: String,
  capacity capacity: Int,
  gap_seconds gap_seconds: Int,
  currency currency: String,
  allow_animals allow_animals: Bool,
  created_at created_at: Timestamp,
  updated_at updated_at: Option(Timestamp),
) -> shared.Resource {
  let assert Ok(id) = uuid.from_string(id)
  shared.Resource(
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
