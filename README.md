# Anchor

A SaaS tool for managing flat and room bookings, Airbnb style.

Hosts create bookable spaces in the admin view and get a configured embed
snippet for the booking widget, which they drop into their own website. Guests
book through the widget, can view their booking via a private link, and cancel
it if needed. The system keeps host and guest informed with automatic emails.

## Packages

| Package   | Target     | What it is                                                      |
| --------- | ---------- | --------------------------------------------------------------- |
| `server/` | Erlang     | wisp/mist API server, SQLite storage                            |
| `shared/` | both       | domain types + JSON codecs — the wire contract                  |
| `widget/` | JavaScript | embeddable `<anchor-widget>` custom element, single `widget.js` |
| `admin/`  | JavaScript | host-facing SPA for spaces, bookings, and embed snippets        |

## Development

Requires `gleam`, `just`, `dbmate`, `mprocs`, and `sqlite3`.

```sh
just dev-all     # api server :8000, widget :1234, admin :1235
just migrate-up  # apply database migrations
just parrot      # regenerate sql bindings after schema changes
just build       # production bundles into server/priv/static
```

See the `Justfile` for all recipes.

# TODO

money.gleam — the bottom of the graph, no deps

- Type: Money (integer minor units; ideally opaque so raw arithmetic can't sidestep the rules)
- Logic: add / sum, apply_percent with the one rounding rule, format-for-currency, compare - This is the single place float-drift is prevented

pricing.gleam — depends only on money

- Types: Condition, Adjustment (stay-price variants only), PricingRule, PricingContext (nights / guests / days-before as plain Ints), PriceBreakdown + BreakdownLine
- Logic: evaluate(rules, context) -> PriceBreakdown (the fold), condition_holds(condition, context) -> Bool
- Codecs: PricingRule to/from JSON (your currently-stubbed pair)
- Stays pure by taking a primitive context, never a Space — that's what keeps it below space in the graph

cancellation.gleam

- Type: CancellationPolicy (the PercentRefund you lift out, or a tiered-by-days policy)
- Logic: refund_for(policy, total, context) -> Money
- Separate because "what's refunded on cancel" is a different question from "what the stay costs"

space.gleam — depends on pricing

- Types: Space (physical unit: capacity, gap, animals, check-in/out, own pricing+currency), Combination (members + own pricing/currency/capacity), Bookable = Single | Combination, Availability/Blocked for host blocks
- Derived functions (the payoff of the type split): gap, allows_animals, checkin, checkout, capacity, pricing, currency — each a pattern-match with the combining rule (max gap, all-allow animals, latest check-in, earliest check-out, owned capacity)
- Membership: blocked_spaces(bookable) -> List(space_id) (drives both the conflict probe and the occupancy rows), combinations_containing(space, all) -> List(Bookable) (the derived "Part of …" badge)
- Codecs

booking.gleam — depends on space

- Types: Contact, Request (now references a single Bookable), Booking = Pending | Confirmed | Cancelled
- Logic: confirm(pending, at) -> Confirmed, cancel(booking, reason, at) -> Cancelled, is_expired(pending, now) -> Bool, nights(request), occupied_spaces(request)
- Codecs

availability.gleam — depends on booking + space

- Types: Interval, conflict-result types
- Logic: overlaps(a, b) -> Bool (the half-open kernel that mirrors the DB trigger), find_conflicts(request, busy: List(Interval))
- This is the read-side check (widget picker, admin conflict panel, calendar). Operates on intervals so the widget gets anonymized busy-ranges, never guest PII

user.gleam / api.gleam — already exist;
User/Credentials, ApiError + codecs

json.gleam — the shared duration_decoder /
timestamp_decoder helpers, pulled out of the
monolith
