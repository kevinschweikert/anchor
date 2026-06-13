# app

The host-facing admin SPA (Lustre + modem), served by the server under
`/admin`. Hosts manage resources, bookings, and business logic here, and grab
the preconfigured widget embed snippet for their site.

## Development

```sh
just dev app    # hot-reloading dev server on :1235, proxies /api to :8000
just build-app  # minified app.js into server/priv/static
```
