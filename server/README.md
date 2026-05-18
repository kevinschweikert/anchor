# Anchor

A self-hosted, generic booking backend written in Gleam.

Anchor models the full lifecycle of a resource booking — from guest request to admin confirmation — with a composable pricing and cancellation engine and a clean JSON API.

Built as the backend for a vacation home booking system, but designed to generalize to any bookable resource: rooms, desks, equipment, or anything that can be reserved over a time window.

## Goals

- **Self-hosted** — no third-party booking services, runs on your own infrastructure
- **Generic** — resources, pricing rules, and availability are fully configurable via the admin API
- **Simple lifecycle** — requests are submitted by guests, reviewed and approved by an admin, and can be cancelled by either side
- **Composable pricing** — nightly rates, flat fees, surcharges, discounts, and cancellation refunds are all expressed as the same kind of rule
- **Embeddable** — ships with a widget that consumes the API and can be dropped into any static site

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
