import db
import gleam/erlang/process
import mist
import router
import web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(conn) = db.open("anchor.db")
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
