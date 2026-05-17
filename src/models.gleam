import gleam/option.{type Option}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

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
  Contact(id: String, name: String, surname: String, email: String)
}

pub type Resource {
  Resource(
    id: String,
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

pub type Request {
  Request(
    id: String,
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
