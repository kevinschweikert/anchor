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
- `just dev widget` / `just dev admin` — hot-reloading lustre dev server for one client package (proxies `/api`, `/login`, `/logout` to :8000)
- `just build` — minified `widget.js` + `admin.js` bundles into `server/priv/static/`
- `just migration <name>` — new dbmate migration in `server/priv/migrations/`
- `just migrate-up` / `just migrate-down` / `just migrate-status` — apply/rollback/inspect migrations
- `just parrot` — apply migrations, then regenerate `server/src/anchor/sql.gleam` from the live schema
- `just seed` — apply `server/priv/seed.sql`
- `just upgrade-daisy` — refresh the vendored daisyUI plugin files in `admin/src/`

Per package (`cd` into it first): `gleam build`, `gleam test`, `gleam format src test`.

`DATABASE_PATH` selects the SQLite file (default: dev db `server/anchor_dev.db`). When overriding, use an absolute path — the server resolves relative paths from `server/`, dbmate from the repo root.

## Architecture

Four Gleam packages tied together by path dependencies (Gleam has no formal workspace concept):

- `shared/` — domain types (`Resource`, `Booking`, `User`, ...) plus their JSON encoders/decoders. This is the wire contract between server and clients; compiled to both targets.
- `server/` — Erlang target. wisp/mist HTTP server, SQLite via sqlight. Routes: `/` landing page, `/demo` widget embed demo, `/login` + `/logout` server-rendered auth pages, `/admin/*` serves the auth-gated admin SPA shell (catch-all so client-side routes survive refresh), `/api/*` JSON API, `/static/*` JS bundles.
- `widget/` — JavaScript target. The embeddable booking widget, registered as the `<anchor-widget>` custom element (`lustre.register`). Ships as one self-contained `widget.js`; third parties embed it with a script tag. Must never grow heavy deps or admin imports. Element attributes (e.g. `resource`) come in via `component.on_attribute_change`.
- `admin/` — JavaScript target. Host-facing SPA (`lustre.application` + modem routing) served under `/admin`, gated by session auth. Fetches the session user via `GET /api/me` on init; the model holds `Option(User)` until it lands.

Server modules live under `server/src/anchor/` (package namespace), matching where parrot generates `sql.gleam`. Server-rendered pages live in `server/src/anchor/views/`.

**Browser-safety invariant for `shared/` (and all JS-target packages):** ids are `String`, not `uuid.Uuid` — youid pulls in `gleam_crypto`, whose JS FFI does a top-level `import "node:crypto"` that crashes browsers. ES module imports are eager, so merely *importing* a Node-only module anywhere in the import graph breaks the widget and admin, even if the function is never called. Keep `youid` (and other Node/Erlang-only deps) in `server/`; UUIDs are generated server-side and cross the wire as strings.

### Database layer

SQL flows one way: queries in `server/src/sql/*.sql` (sqlc annotation syntax) → `just parrot` → generated `server/src/anchor/sql.gleam` (marked DO NOT EDIT — never modify by hand). Parrot emits one nominal row type per query; these are quarantined in their persistence module (e.g. `server/src/anchor/resource.gleam`), which destructures each row and funnels it through a single `row_to_*` constructor into the `shared` domain type. Follow that pattern for new entities: generated row types stay in the persistence module, only `shared` types cross the API. Prefer explicit column lists over `SELECT *` so generated row types only carry what the caller needs.

Schema changes go through dbmate migrations (`server/priv/migrations/`, single-file `-- migrate:up` / `-- migrate:down` format), then `just parrot` to regenerate bindings.

**Timestamp invariant:** `TIMESTAMP` columns store unix **microseconds** (the pog convention used by both parrot's `dev.datetime_decoder` and `db.parrot_to_sqlight`). Never write plain `unixepoch()` seconds in migrations or seeds.

### Auth & sessions

- Login: argon2id via `argus`. The encoded hash embeds algorithm, params, and per-password salt — `users.password_hash` is the only column, no separate salt. When creating users (seed/signup), supply a 16-random-byte salt to `argus.hash`.
- **Hash containment invariant:** the password hash never leaves `users.authenticate` — `shared.User` has no hash field, and the session-lookup SQL selects only `id, email`, so a leak is unrepresentable. Preserve this when touching auth or user queries.
- Sessions: random id stored in the `sessions` table (30-day TTL) and in a `sid` cookie set with `wisp.Signed`. Signing is defense in depth: a tampered cookie is rejected before it hits the DB. Expired sessions are cleaned lazily on each login.
- Two middlewares in `web.gleam`, same check, different failure protocol: `require_admin` (browser navigation → redirect to `/login`) gates the SPA shell; `require_api_user` (API → `401`) gates private `/api/*` endpoints. Don't redirect from API endpoints — fetch follows redirects silently and decoders fail far from the cause.
- Client identity: the SPA fetches the session user via `GET /api/me` (an rsvp effect in `init`); there is no server-side embedding of user data in the shell. A 401 there triggers `modem.load("/login")` — a full-document navigation, since `/login` lives outside the SPA.

### Admin dev workflow

`just dev admin` (:1235) is the primary loop: hot reload with the *real* session. The dev server proxies `/api`, `/login`, `/logout` to :8000 and forwards headers both ways; cookies ignore ports, so a login performed on :1235 sets the same `localhost` cookie the proxied API calls then carry — `/api/me` returns the real session user on both origins.

If `main()` ever reads more from the page than `#app`, that markup must exist in *both* the dev-tools page (`tools.lustre.html.body` in `admin/gleam.toml`) and the server shell (`views/admin.gleam`).

`:8000/admin` after `just build` is the pre-flight check — the only place the real shell, embed, and minified bundle are exercised together.

### Styling

Admin uses Tailwind v4 (standalone CLI via lustre_dev_tools) + daisyUI, vendored as pre-bundled plugin files (`admin/src/daisyui.js`, `daisyui-theme.js`) loaded with `@plugin "./daisyui.js"` in `admin.css`. No npm and no CDN — update via `just upgrade-daisy` and commit the result. The name-based `@plugin "daisyui"` form is npm-only and won't work here.

### Widget constraints

The widget runs on third-party origins. Before adding API calls to it: relative URLs like `/api/...` resolve against the embedder's domain, so the API host must be configurable (attribute or build-time), and the public API endpoints need CORS headers. The widget dev server's page body is set via `tools.lustre.html.body` in `widget/gleam.toml` (a bare `#app` div renders nothing because the widget only registers a custom element).
