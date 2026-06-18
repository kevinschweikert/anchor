import gleam/dynamic/decode
import gleam/float
import gleam/json
import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import money
import pricing

fn duration_decoder() -> decode.Decoder(Duration) {
  use seconds <- decode.then(decode.float)
  {
    seconds *. 1000.0
    |> float.round
    |> duration.milliseconds()
    |> decode.success()
  }
}

fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use rfc_string <- decode.then(decode.string)
  case timestamp.parse_rfc3339(rfc_string) {
    Ok(timestamp) -> decode.success(timestamp)
    Error(_) -> decode.failure(timestamp.system_time(), "RFC3339 Timestamp")
  }
}

pub type Contact {
  Contact(id: String, name: String, surname: String, email: String)
}

pub type Space {
  Space(
    id: String,
    name: String,
    capacity: Int,
    gap: Duration,
    currency: String,
    pricing: pricing.Pricing,
    allow_animals: Bool,
    created_at: Timestamp,
    updated_at: Option(Timestamp),
  )
}

pub fn space_decoder() -> decode.Decoder(Space) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use capacity <- decode.field("capacity", decode.int)
  use gap <- decode.field("gap", duration_decoder())
  use currency <- decode.field("currency", decode.string)
  // use pricing <- decode.field("pricing", decode.list(todo as "Decoder for PricingRule"))
  // use availability <- decode.field("availability", decode.list(todo as "Decoder for Availability"))
  use allow_animals <- decode.field("allow_animals", decode.bool)
  use created_at <- decode.field("created_at", timestamp_decoder())
  use updated_at <- decode.field(
    "updated_at",
    decode.optional(timestamp_decoder()),
  )
  decode.success(Space(
    id:,
    name:,
    capacity:,
    gap:,
    currency:,
    pricing: pricing.Pricing(
      base: pricing.Flat(money.new(0)),
      fees: [],
      discounts: [],
      surcharges: [],
    ),
    allow_animals:,
    created_at:,
    updated_at:,
  ))
}

pub fn space_to_json(space: Space) -> json.Json {
  let Space(
    id:,
    name:,
    capacity:,
    gap:,
    currency:,
    pricing: _,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = space
  json.object([
    #("id", json.string(id)),
    #("name", json.string(name)),
    #("capacity", json.int(capacity)),
    #("gap", duration.to_seconds(gap) |> json.float),
    #("currency", json.string(currency)),
    // #("pricing", json.array(pricing, todo as "Encoder for PricingRule")),
    // #(
    //   "availability",
    //   json.array(availability, todo as "Encoder for Availability"),
    // ),
    #("allow_animals", json.bool(allow_animals)),
    #(
      "created_at",
      timestamp.to_rfc3339(created_at, calendar.utc_offset) |> json.string,
    ),
    #("updated_at", case updated_at {
      option.None -> json.null()
      option.Some(value) ->
        timestamp.to_rfc3339(value, calendar.utc_offset) |> json.string
    }),
  ])
}

pub type NewSpace {
  NewSpace(
    name: String,
    capacity: Int,
    gap_seconds: Int,
    currency: String,
    allow_animals: Bool,
  )
}

pub fn new_space_to_json(new_space: NewSpace) -> json.Json {
  let NewSpace(name:, capacity:, gap_seconds:, currency:, allow_animals:) =
    new_space
  json.object([
    #("name", json.string(name)),
    #("capacity", json.int(capacity)),
    #("gap_seconds", json.int(gap_seconds)),
    #("currency", json.string(currency)),
    #("allow_animals", json.bool(allow_animals)),
  ])
}

pub fn new_space_decoder() -> decode.Decoder(NewSpace) {
  use name <- decode.field("name", decode.string)
  use capacity <- decode.field("capacity", decode.int)
  use gap_seconds <- decode.field("gap_seconds", decode.int)
  use currency <- decode.field("currency", decode.string)
  use allow_animals <- decode.field("allow_animals", decode.bool)
  decode.success(NewSpace(
    name:,
    capacity:,
    gap_seconds:,
    currency:,
    allow_animals:,
  ))
}

pub type Request {
  Request(
    id: String,
    start: Timestamp,
    end: Timestamp,
    contact: Contact,
    people: Int,
    animals: Option(Bool),
    spaces: List(Space),
    comment: Option(String),
  )
}

pub type Booking {
  Pending(request: Request, expires_at: Timestamp)
  Confirmed(request: Request, confirmed_at: Timestamp)
  Cancelled(request: Request, reason: Option(String), cancelled_at: Timestamp)
}

pub type User {
  User(id: String, name: String, email: String)
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use email <- decode.field("email", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(User(id:, email:, name:))
}

pub fn user_to_json(user: User) -> json.Json {
  let User(id:, email:, name:) = user
  json.object([
    #("id", json.string(id)),
    #("email", json.string(email)),
    #("name", json.string(name)),
  ])
}

pub type Credentials {
  Credentials(email: String, password: String)
}

pub fn credentials_to_json(credentials: Credentials) -> json.Json {
  let Credentials(email:, password:) = credentials
  json.object([
    #("email", json.string(email)),
    #("password", json.string(password)),
  ])
}

pub fn credentials_decoder() -> decode.Decoder(Credentials) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(Credentials(email:, password:))
}

pub type ApiError {
  BadRequest
  BadCredentials
  ServerError
}

pub fn api_error_decoder() -> decode.Decoder(ApiError) {
  use variant <- decode.field("error", decode.string)
  case variant {
    "bad_request" -> decode.success(BadRequest)
    "bad_credentials" -> decode.success(BadCredentials)
    "server_error" -> decode.success(ServerError)
    _ -> decode.failure(BadRequest, "ApiError")
  }
}

pub fn api_error_to_json(api_error: ApiError) -> json.Json {
  json.object([
    #("error", case api_error {
      BadRequest -> json.string("bad_request")
      BadCredentials -> json.string("bad_credentials")
      ServerError -> json.string("server_error")
    }),
  ])
}
