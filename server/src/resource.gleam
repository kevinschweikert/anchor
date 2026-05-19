import anchor/sql
import db
import gleam/list
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import shared
import sqlight
import youid/uuid

pub type Error {
  DbError(sqlight.Error)
  ExpectedOnlyOne
}

pub fn list_resources(
  conn: sqlight.Connection,
) -> Result(List(shared.Resource), sqlight.Error) {
  let #(sql, with, expecting) = sql.all_resources()
  let rows = sqlight.query(sql, on: conn, with:, expecting:)
  use rows <- result.map(rows)
  use r <- list.map(rows)
  let sql.AllResources(
    id:,
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = r
  shared.Resource(
    id: uuid.from_string(id)
      |> result.lazy_unwrap(fn() { panic as "unable to parse uuid" }),
    name:,
    capacity:,
    gap: gap_seconds |> duration.seconds,
    currency:,
    allow_animals:,
    created_at:,
    updated_at:,
    availability: [],
    pricing: [],
  )
}

pub fn get_resource(
  id: String,
  conn: sqlight.Connection,
) -> Result(shared.Resource, Error) {
  let #(sql, with, expecting) = sql.get_resource(id)
  let with = list.map(with, db.parrot_to_sqlight)
  let row = sqlight.query(sql, on: conn, with:, expecting:)
  case row {
    Ok([r]) ->
      Ok(
        shared.Resource(
          id: uuid.from_string(r.id)
            |> result.lazy_unwrap(fn() { panic as "unable to parse uuid" }),
          name: r.name,
          capacity: r.capacity,
          gap: r.gap_seconds |> duration.seconds,
          currency: r.currency,
          allow_animals: r.allow_animals,
          created_at: r.created_at,
          updated_at: r.updated_at,
          availability: [],
          pricing: [],
        ),
      )
    Ok(_) -> Error(ExpectedOnlyOne)
    Error(err) -> Error(DbError(err))
  }
}

pub fn create_resource(
  id,
  name,
  capacity,
  gap_seconds,
  currency,
  allow_animals,
  conn: sqlight.Connection,
) {
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
  let row = sqlight.query(sql, on: conn, with:, expecting:)
  case row {
    Ok([r]) ->
      Ok(
        shared.Resource(
          id: uuid.from_string(r.id)
            |> result.lazy_unwrap(fn() { panic as "unable to parse uuid" }),
          name: r.name,
          capacity: r.capacity,
          gap: r.gap_seconds |> duration.seconds,
          currency: r.currency,
          allow_animals: r.allow_animals,
          created_at: r.created_at,
          updated_at: r.updated_at,
          availability: [],
          pricing: [],
        ),
      )
    Ok(_) -> Error(ExpectedOnlyOne)
    Error(err) -> Error(DbError(err))
  }
}
