# widget

The embeddable booking widget, built with Lustre and registered as the
`<anchor-widget>` custom element. Bundles to a single self-contained
`widget.js` — the only file hosts need on their site:

```html
<script type="module" src="https://<anchor-host>/static/widget.js"></script>
<anchor-widget space="<space-id>"></anchor-widget>
```

Hosts get this snippet preconfigured from the admin view.

## Development

```sh
just dev widget    # hot-reloading dev server on :1234, proxies /api to :8000
just build-widget  # minified widget.js into server/priv/static
```
