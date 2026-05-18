import anchor/sql
import gleam/list
import gleam/result
import gleam/time/duration
import shared
import sqlight
import youid/uuid

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
