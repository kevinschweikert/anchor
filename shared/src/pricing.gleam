import gleam/list
import money.{type Amount}

pub type Pricing {
  Pricing(
    base: Base,
    fees: List(Rule(Fee)),
    discounts: List(Rule(Discount)),
    surcharges: List(Rule(Surcharge)),
  )
}

pub type Rule(adjustment) {
  Rule(condition: Condition, adjustment: adjustment, label: String)
}

pub type Condition {
  Always
  NightsAtMost(Int)
  NightsAtLeast(Int)
  PeopleAbove(Int)
  DaysBeforeStart(Int)
}

pub type Base {
  Flat(Amount)
  PerNight(Amount)
  PerNightPerPerson(Amount)
}

pub type Fee {
  FlatFee(Amount)
  PerNightFee(Amount)
  PerNightPerPersonFee(Amount)
}

pub type Discount {
  PercentDiscount(Int)
}

pub type Surcharge {
  PercentSurcharge(Int)
}

pub type Context {
  PricingContext(nights: Int, guests: Int, days_between_booking_and_start: Int)
}

pub type Change {
  Applied(label: String, amount: Amount)
  Skipped(label: String)
}

pub type Breakdown {
  Breakdown(
    base: Amount,
    fees: List(Change),
    discounts: List(Change),
    surcharges: List(Change),
    total: Amount,
  )
}

pub fn breakdown(pricing: Pricing, ctx: Context) {
  let base = apply_base(pricing.base, ctx)

  let #(fees, fee_total) =
    apply_phase(base, pricing.fees, ctx, fee_amount(_, ctx))

  let #(discounts, discount_total) =
    apply_phase(fee_total, pricing.discounts, ctx, discount_amount(_, fee_total))

  let #(surcharges, total) =
    apply_phase(discount_total, pricing.surcharges, ctx, surcharge_amount(
      _,
      discount_total,
    ))

  Breakdown(base:, fees:, discounts:, surcharges:, total:)
}

fn apply_base(base: Base, ctx: Context) -> Amount {
  case base {
    Flat(amount) -> amount
    PerNight(amount) -> money.multiply(amount, ctx.nights)
    PerNightPerPerson(amount) -> money.multiply(amount, ctx.nights * ctx.guests)
  }
}

fn apply_phase(
  total: Amount,
  rules: List(Rule(a)),
  ctx: Context,
  amount: fn(a) -> Amount,
) -> #(List(Change), Amount) {
  let changes = {
    use rule <- list.map(rules)
    use <- with_condition(rule, ctx)
    let Rule(condition: _, label:, adjustment:) = rule
    Applied(label:, amount: amount(adjustment))
  }
  #(changes, apply_changes(total, changes))
}

fn fee_amount(fee: Fee, ctx: Context) -> Amount {
  case fee {
    FlatFee(amount) -> amount
    PerNightFee(amount) -> money.multiply(amount, ctx.nights)
    PerNightPerPersonFee(amount) ->
      money.multiply(amount, ctx.nights * ctx.guests)
  }
}

fn discount_amount(discount: Discount, subtotal: Amount) -> Amount {
  case discount {
    PercentDiscount(percentage) ->
      money.percentage(subtotal, percentage)
      |> money.multiply(-1)
  }
}

fn surcharge_amount(surcharge: Surcharge, subtotal: Amount) -> Amount {
  case surcharge {
    PercentSurcharge(percentage) -> money.percentage(subtotal, percentage)
  }
}

fn apply_changes(base: Amount, changes: List(Change)) {
  use running_total, change <- list.fold(changes, base)
  case change {
    Applied(label: _, amount:) -> money.add(running_total, amount)
    Skipped(label: _) -> running_total
  }
}

fn with_condition(rule: Rule(a), ctx: Context, fun: fn() -> Change) -> Change {
  let bool = case rule.condition {
    Always -> True
    NightsAtMost(nights) -> ctx.nights <= nights
    NightsAtLeast(nights) -> ctx.nights >= nights
    PeopleAbove(guests) -> ctx.guests > guests
    DaysBeforeStart(days) -> ctx.days_between_booking_and_start < days
  }

  case bool {
    True -> fun()
    False -> Skipped(label: rule.label)
  }
}
