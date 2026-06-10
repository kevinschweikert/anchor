# server

The Anchor API server (Erlang target): wisp + mist, SQLite via sqlight.

It models the booking lifecycle — guest request, confirmation, cancellation —
with composable pricing rules, and sends automatic mails to host and guest.

Routes:

- `/api/*` — JSON API consumed by the widget and the admin SPA
- `/admin/*` — serves the admin SPA shell
- `/demo` — widget embed demo
- `/static/*` — built JS bundles

SQL queries live in `src/sql/*.sql`; `just parrot` regenerates the typed
bindings in `src/anchor/sql.gleam`. The schema is managed with dbmate
migrations in `priv/migrations/`. See the root README and `Justfile` for the
full workflow.
