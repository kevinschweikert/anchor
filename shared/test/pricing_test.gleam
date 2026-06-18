import money
import pricing

fn ctx() -> pricing.Context {
  pricing.PricingContext(
    nights: 1,
    guests: 1,
    days_between_booking_and_start: 1,
  )
}

fn always(adjustment: a, label: String) -> pricing.Rule(a) {
  pricing.Rule(condition: pricing.Always, adjustment:, label:)
}

fn base_only(base: pricing.Base) {
  pricing.Pricing(base:, fees: [], discounts: [], surcharges: [])
}

pub fn base_flat_test() -> Nil {
  let p = base_only(pricing.Flat(money.new(10)))
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(10)
}

pub fn base_per_night_test() -> Nil {
  let p = base_only(pricing.PerNight(money.new(10)))
  let ctx = pricing.PricingContext(..ctx(), nights: 3)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(30)
  assert breakdown.total == money.new(30)
}

pub fn base_per_night_per_person_test() -> Nil {
  let p = base_only(pricing.PerNightPerPerson(money.new(10)))
  let ctx = pricing.PricingContext(..ctx(), nights: 3, guests: 6)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(180)
  assert breakdown.total == money.new(180)
}

pub fn flat_fee_adds_to_total_test() -> Nil {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), fees: [
      always(pricing.FlatFee(money.new(20)), "Extra"),
    ])
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)
}

pub fn discount_reduces_total_test() {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), discounts: [
      always(pricing.PercentDiscount(20), ""),
    ])
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(8)
}

pub fn multiple_discounts_reference_same_base_test() {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(100))), discounts: [
      always(pricing.PercentDiscount(10), ""),
      always(pricing.PercentDiscount(10), ""),
    ])
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(100)
  assert breakdown.total == money.new(80)
}

pub fn surcharge_increases_total_test() {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), surcharges: [
      always(pricing.PercentSurcharge(20), ""),
    ])
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(12)
}

pub fn multiple_surcharges_reference_same_base_test() {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(100))), surcharges: [
      always(pricing.PercentSurcharge(10), ""),
      always(pricing.PercentSurcharge(10), ""),
    ])
  let breakdown = pricing.breakdown(p, ctx())

  assert breakdown.base == money.new(100)
  assert breakdown.total == money.new(120)
}

pub fn condition_nights_at_most_test() -> Nil {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), fees: [
      pricing.Rule(pricing.NightsAtMost(3), pricing.FlatFee(money.new(20)), ""),
    ])
  let ctx = pricing.PricingContext(..ctx(), nights: 4)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(10)

  let ctx = pricing.PricingContext(..ctx, nights: 2)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)

  let ctx = pricing.PricingContext(..ctx, nights: 3)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)
}

pub fn condition_nights_at_least_test() -> Nil {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), fees: [
      pricing.Rule(pricing.NightsAtLeast(3), pricing.FlatFee(money.new(20)), ""),
    ])
  let ctx = pricing.PricingContext(..ctx(), nights: 4)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)

  let ctx = pricing.PricingContext(..ctx, nights: 2)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(10)

  let ctx = pricing.PricingContext(..ctx, nights: 3)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)
}

pub fn condition_people_above_test() -> Nil {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), fees: [
      pricing.Rule(pricing.PeopleAbove(3), pricing.FlatFee(money.new(20)), ""),
    ])
  let ctx = pricing.PricingContext(..ctx(), guests: 4)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)

  let ctx = pricing.PricingContext(..ctx, guests: 2)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(10)
}

pub fn condition_days_before_test() -> Nil {
  let p =
    pricing.Pricing(..base_only(pricing.Flat(money.new(10))), fees: [
      pricing.Rule(
        pricing.DaysBeforeStart(3),
        pricing.FlatFee(money.new(20)),
        "",
      ),
    ])
  let ctx = pricing.PricingContext(..ctx(), days_between_booking_and_start: 4)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(10)

  let ctx = pricing.PricingContext(..ctx, days_between_booking_and_start: 2)
  let breakdown = pricing.breakdown(p, ctx)

  assert breakdown.base == money.new(10)
  assert breakdown.total == money.new(30)
}
