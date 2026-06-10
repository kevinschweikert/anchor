# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Anchor is a SaaS tool to manage flat/room bookings, Airbnb style. Use cases:

- Hosts use the admin view to create bookable resources and get a preconfigured embed code snippet
- Hosts embed the booking widget on their own website; guests book through it
- Guests can view their booking (via a private per-booking link) and cancel it if needed
- The system automatically sends mails to host and guest

"Host" = the SaaS customer managing resources; "guest" = the end user booking them.

## Commands

Workflow commands are in the root `Justfile`:

- `just dev-all` — full dev environment in one mprocs session: API server (:8000), widget dev server (:1234), admin dev server (:1235)
- `just run` — API server only
- `just dev widget` / `just dev admin` — hot-reloading lustre dev server for one client package (proxies `/api` to :8000)
- `just build` — minified `widget.js` + `admin.js` bundles into `server/priv/static/`
- `just migration <name>` — new dbmate migration in `server/priv/migrations/`
- `just migrate-up` / `just migrate-down` / `just migrate-status` — apply/rollback/inspect migrations
- `just parrot` — apply migrations, then regenerate `server/src/anchor/sql.gleam` from the live schema
- `just seed` — apply `server/priv/seed.sql`

Per package (`cd` into it first): `gleam build`, `gleam test`, `gleam format src test`.

`DATABASE_PATH` selects the SQLite file (default: dev db `server/anchor_dev.db`). When overriding, use an absolute path — the server resolves relative paths from `server/`, dbmate from the repo root.

## Architecture

Four Gleam packages tied together by path dependencies (Gleam has no formal workspace concept):

- `shared/` — domain types (`Resource`, `Booking`, ...) plus their JSON encoders/decoders. This is the wire contract between server and clients; compiled to both targets.
- `server/` — Erlang target. wisp/mist HTTP server, SQLite via sqlight. Routes: `/` landing page, `/demo` widget embed demo, `/admin/*` serves the admin SPA shell (catch-all so client-side routes survive refresh), `/api/*` JSON API, `/static/*` JS bundles.
- `widget/` — JavaScript target. The embeddable booking widget, registered as the `<anchor-widget>` custom element (`lustre.register`). Ships as one self-contained `widget.js`; third parties embed it with a script tag. Must never grow heavy deps or admin imports. Element attributes (e.g. `resource`) come in via `component.on_attribute_change`.
- `admin/` — JavaScript target. Staff-facing SPA (`lustre.application` + modem routing) served under `/admin`. Will be gated by session auth (see `PLAN.md`).

Server modules live under `server/src/anchor/` (package namespace), matching where parrot generates `sql.gleam`.

### Database layer

SQL flows one way: queries in `server/src/sql/*.sql` (sqlc annotation syntax) → `just parrot` → generated `server/src/anchor/sql.gleam` (marked DO NOT EDIT — never modify by hand). Parrot emits one nominal row type per query; these are quarantined in `server/src/anchor/resource.gleam`, which destructures each row and funnels it through a single `row_to_resource` constructor into the `shared` domain type. Follow that pattern for new entities: generated row types stay in the persistence module, only `shared` types cross the API.

Schema changes go through dbmate migrations (`server/priv/migrations/`, single-file `-- migrate:up` / `-- migrate:down` format), then `just parrot` to regenerate bindings.

**Timestamp invariant:** `TIMESTAMP` columns store unix **microseconds** (the pog convention used by both parrot's `dev.datetime_decoder` and `db.parrot_to_sqlight`). Never write plain `unixepoch()` seconds in migrations or seeds.

### Widget constraints

The widget runs on third-party origins. Before adding API calls to it: relative URLs like `/api/...` resolve against the embedder's domain, so the API host must be configurable (attribute or build-time), and the public API endpoints need CORS headers. The widget dev server's page body is set via `tools.lustre.html.body` in `widget/gleam.toml` (a bare `#app` div renders nothing because the widget only registers a custom element).

## Project context

`PLAN.md` holds the design notes for admin session auth (argon2 via argus, session IDs in signed cookies, `require_admin` middleware gating `/admin`).
