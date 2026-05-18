import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid

pub type Condition {
  Always
  NightsAtMost(Int)
  NightsAtLeast(Int)
  PeopleAbove(Int)
  DaysBeforeStart(Int)
}

pub type Adjustment {
  FlatFee(Float)
  PerNightFee(Float)
  PerNightPerPersonFee(Float)
  PercentDiscount(Int)
  PercentSurcharge(Int)
  PercentRefund(Int)
}

pub type PricingRule {
  PricingRule(condition: Condition, adjustment: Adjustment, label: String)
}

pub type Availability {
  Blocked(start: Timestamp, end: Timestamp)
}

pub type Contact {
  Contact(id: uuid.Uuid, name: String, surname: String, email: String)
}

pub type Resource {
  Resource(
    id: uuid.Uuid,
    name: String,
    capacity: Int,
    gap: Duration,
    currency: String,
    pricing: List(PricingRule),
    availability: List(Availability),
    allow_animals: Bool,
    created_at: Timestamp,
    updated_at: Option(Timestamp),
  )
}

pub fn resource_to_json(resource: Resource) -> json.Json {
  let Resource(
    id:,
    name:,
    capacity:,
    gap:,
    currency:,
    pricing: _,
    availability: _,
    allow_animals:,
    created_at:,
    updated_at:,
  ) = resource
  json.object([
    #("id", uuid.to_string(id) |> json.string),
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

pub type Request {
  Request(
    id: uuid.Uuid,
    start: Timestamp,
    end: Timestamp,
    contact: Contact,
    people: Int,
    animals: Option(Bool),
    resources: List(Resource),
    comment: Option(String),
  )
}

pub type Booking {
  Pending(request: Request, expires_at: Timestamp)
  Confirmed(request: Request, confirmed_at: Timestamp)
  Cancelled(request: Request, reason: Option(String), cancelled_at: Timestamp)
}
