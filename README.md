# Anchor

A SaaS tool for managing flat and room bookings, Airbnb style.

Hosts create bookable resources in the admin view and get a configured embed
snippet for the booking widget, which they drop into their own website. Guests
book through the widget, can view their booking via a private link, and cancel
it if needed. The system keeps host and guest informed with automatic emails.

## Packages

| Package   | Target     | What it is                                                       |
| --------- | ---------- | ---------------------------------------------------------------- |
| `server/` | Erlang     | wisp/mist API server, SQLite storage                              |
| `shared/` | both       | domain types + JSON codecs — the wire contract                    |
| `widget/` | JavaScript | embeddable `<anchor-widget>` custom element, single `widget.js`   |
| `admin/`  | JavaScript | host-facing SPA for resources, bookings, and embed snippets       |

## Development

Requires `gleam`, `just`, `dbmate`, `mprocs`, and `sqlite3`.

```sh
just dev-all     # api server :8000, widget :1234, admin :1235
just migrate-up  # apply database migrations
just parrot      # regenerate sql bindings after schema changes
just build       # production bundles into server/priv/static
```

See the `Justfile` for all recipes.
