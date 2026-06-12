import anchor/db
import anchor/router
import anchor/web.{Context}
import envoy
import gleam/erlang/process
import gleam/result
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let db_path =
    envoy.get("ANCHOR_DATABASE_PATH") |> result.unwrap("anchor_dev.db")
  let secret_key_base =
    envoy.get("ANCHOR_SECRET_KEY_BASE")
    |> result.lazy_unwrap(fn() { wisp.random_string(64) })
  let assert Ok(conn) = db.open(db_path)
  let ctx = Context(static_directory: static_directory(), conn:)
  let handler = router.handle_request(_, ctx)
  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new()
    |> mist.port(8000)
    |> mist.start()

  process.sleep_forever()
}

fn static_directory() {
  let assert Ok(priv_dir) = wisp.priv_directory("anchor")
  priv_dir <> "/static"
}
