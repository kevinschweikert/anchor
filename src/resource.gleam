import anchor/sql
import gleam/json
import gleam/list
import gleam/result
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import models
import sqlight

pub fn to_json(r: models.Resource) -> json.Json {
  json.object([
    #("id", json.string(r.id)),
    #("name", json.string(r.name)),
    #(
      "created_at",
      json.string(r.created_at |> timestamp.to_rfc3339(calendar.utc_offset)),
    ),
  ])
}

pub fn list_resources(
  conn: sqlight.Connection,
) -> Result(List(models.Resource), sqlight.Error) {
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
  models.Resource(
    id:,
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
