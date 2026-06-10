# shared

Domain types (`Resource`, `Booking`, `Contact`, pricing rules, …) and their
JSON encoders/decoders, shared by `server`, `widget`, and `admin`.

This package is the wire contract: anything that crosses the API lives here,
and it compiles on both the Erlang and JavaScript targets.
