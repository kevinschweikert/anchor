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

- `just dev-all` — full dev environment in one mprocs session: API server (:8000), widget dev server (:1234), app dev server (:1235)
- `just run` — API server only
- `just dev widget` / `just dev app` — hot-reloading lustre dev server for one client package (proxies `/api` to :8000)
- `just build-all` — minified `widget.js` + `app.js` bundles into `server/priv/static/` (`just build <project>` for a single package)
- `just migration <name>` — new dbmate migration in `server/priv/migrations/`
- `just migrate-up` / `just migrate-down` / `just migrate-status` — apply/rollback/inspect migrations
- `just parrot` — apply migrations, then regenerate `server/src/anchor/sql.gleam` from the live schema
- `just seed` — apply `server/priv/seed.sql`
- `just upgrade-daisy` — refresh the vendored daisyUI plugin files in `app/src/`

Per package (`cd` into it first): `gleam build`, `gleam test`, `gleam format src test`.

`DATABASE_PATH` selects the SQLite file (default: dev db `server/anchor_dev.db`). When overriding, use an absolute path — the server resolves relative paths from `server/`, dbmate from the repo root.

## Architecture

Four Gleam packages tied together by path dependencies (Gleam has no formal workspace concept):

- `shared/` — domain types (`Resource`, `Booking`, `User`, ...) plus their JSON encoders/decoders. This is the wire contract between server and clients; compiled to both targets.
- `server/` — Erlang target. wisp/mist HTTP server, SQLite via sqlight. Routes: `/api/*` JSON API (`/api/me`, `/api/login`, `/api/logout`, resources), `/static/*` JS bundles, and a catch-all that serves the single **public** SPA shell (`views/app.gleam`) for every other GET so client-side routes survive refresh. The SPA owns all UI (`/`, `/login`, `/admin/*`).
- `widget/` — JavaScript target. The embeddable booking widget, registered as the `<anchor-widget>` custom element (`lustre.register`). Ships as one self-contained `widget.js`; third parties embed it with a script tag. Must never grow heavy deps or app imports. Element attributes (e.g. `resource`) come in via `component.on_attribute_change`.
- `app/` — JavaScript target. The whole frontend: one `lustre.application` + modem SPA owning public pages (`/`, `/login`) and internal pages (`/admin/*`). Session identity is a 3-state `Auth` (`Checking`/`Authenticated`/`Anonymous`) loaded via `GET /api/me` in `init` — `Checking` exists so a refresh doesn't flash the login page before `/api/me` answers. Access tier is encoded in the route type itself: `Route` wraps `PublicRoute` / `GuestRoute` / `AdminRoute`, so a page can't be added without choosing a tier, and `admin_view` takes an `AdminRoute` (not `Route`), so a non-admin page there is unrepresentable. A `guard` matches the tier to drive client-side `modem.push` redirects. **These client guards are UX, not security** — the real boundary is the API (`require_api_user` → 401); the shell is public and ships to everyone.

Server modules live under `server/src/anchor/` (package namespace), matching where parrot generates `sql.gleam`. The single SPA shell HTML lives in `server/src/anchor/views/app.gleam`.

**Browser-safety invariant for `shared/` (and all JS-target packages):** ids are `String`, not `uuid.Uuid` — youid pulls in `gleam_crypto`, whose JS FFI does a top-level `import "node:crypto"` that crashes browsers. ES module imports are eager, so merely *importing* a Node-only module anywhere in the import graph breaks the widget and app, even if the function is never called. Keep `youid` (and other Node/Erlang-only deps) in `server/`; UUIDs are generated server-side and cross the wire as strings.

### Database layer

SQL flows one way: queries in `server/src/sql/*.sql` (sqlc annotation syntax) → `just parrot` → generated `server/src/anchor/sql.gleam` (marked DO NOT EDIT — never modify by hand). Parrot emits one nominal row type per query; these are quarantined in their persistence module (e.g. `server/src/anchor/resource.gleam`), which destructures each row and funnels it through a single `row_to_*` constructor into the `shared` domain type. Follow that pattern for new entities: generated row types stay in the persistence module, only `shared` types cross the API. Prefer explicit column lists over `SELECT *` so generated row types only carry what the caller needs.

Schema changes go through dbmate migrations (`server/priv/migrations/`, single-file `-- migrate:up` / `-- migrate:down` format), then `just parrot` to regenerate bindings.

**Timestamp invariant:** `TIMESTAMP` columns store unix **microseconds** (the pog convention used by both parrot's `dev.datetime_decoder` and `db.parrot_to_sqlight`). Never write plain `unixepoch()` seconds in migrations or seeds.

### Auth & sessions

- Login: argon2id via `argus`. The encoded hash embeds algorithm, params, and per-password salt — `users.password_hash` is the only column, no separate salt. When creating users (seed/signup), supply a 16-random-byte salt to `argus.hash`.
- **Hash containment invariant:** the password hash never leaves `users.authenticate` — `shared.User` has no hash field, and the session-lookup SQL selects only `id, email`, so a leak is unrepresentable. Preserve this when touching auth or user queries.
- Sessions: random id stored in the `sessions` table (30-day TTL) and in a `sid` cookie set with `wisp.Signed`. Signing is defense in depth: a tampered cookie is rejected before it hits the DB. Expired sessions are cleaned lazily on each login.
- One auth gate in `web.gleam`: `require_api_user` (private `/api/*` → `401`). The SPA shell is served publicly for every GET — there's deliberately no server-side redirect guard, because the shell has to host the login page itself. Don't redirect from API endpoints — fetch follows redirects silently and decoders fail far from the cause.
- Login flow: a `fetch` POST to `/api/login` with `shared.Credentials` JSON (validated server-side); on success the signed `sid` cookie is set and the `User` is returned in the body, so there's no extra `/api/me` round-trip after login. Logout is `POST /api/logout` (returns `200`, clears the cookie) — JSON, never a redirect, since the SPA drives its own navigation. A `401` from `/api/me` flips `Auth` to `Anonymous` and the guard `modem.push`es to `/login`, an in-SPA route.
- CSRF: `csrf_protection` in `web.gleam` wraps `wisp.csrf_known_header_protection`, letting an **exact-match** trusted `Origin` skip the same-origin check. `Context.trusted_origins` comes from `ANCHOR_TRUSTED_ORIGINS` (comma-separated) and is **empty by default**, so prod stays fully protected. Dev sets `http://localhost:1235` (in `mise.toml`) so the proxied dev origin can log in. The check keys on `Origin` (not `Host`), so it survives the proxy rewriting `Host`.

### App dev workflow

`just dev app` (:1235) is the primary loop: hot reload with the *real* session. The dev server proxies `/api` to :8000 and forwards headers both ways; cookies ignore ports, so a login performed on :1235 sets the same `localhost` cookie the proxied API calls then carry — `/api/me` returns the real session user on both origins. The page origin (`:1235`) differs from the API host (`:8000`), so wisp's CSRF origin check rejects the login POST unless `:1235` is in `ANCHOR_TRUSTED_ORIGINS` (set in `mise.toml`).

If `main()` ever reads more from the page than `#app`, that markup must exist in *both* the dev-tools page (`tools.lustre.html.body` in `app/gleam.toml`) and the server shell (`views/app.gleam`).

`:8000` after `just build-all` is the pre-flight check — the only place the real shell and minified bundle are exercised together (any route serves the shell, so `:8000/` or `:8000/admin` both work).

### Styling

The app uses Tailwind v4 (standalone CLI via lustre_dev_tools) + daisyUI, vendored as pre-bundled plugin files (`app/src/daisyui.js`, `daisyui-theme.js`) loaded with `@plugin "./daisyui.js"` in `app.css`. No npm and no CDN — update via `just upgrade-daisy` and commit the result. The name-based `@plugin "daisyui"` form is npm-only and won't work here.

### Widget constraints

The widget runs on third-party origins. Before adding API calls to it: relative URLs like `/api/...` resolve against the embedder's domain, so the API host must be configurable (attribute or build-time), and the public API endpoints need CORS headers. The widget dev server's page body is set via `tools.lustre.html.body` in `widget/gleam.toml` (a bare `#app` div renders nothing because the widget only registers a custom element).
