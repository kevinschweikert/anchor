import anchor/sessions
import gleam/option
import shared.{type User}
import sqlight
import wisp

pub type Context {
  Context(
    conn: sqlight.Connection,
    static_directory: String,
    user: option.Option(User),
  )
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

pub fn require_admin(req: wisp.Request, ctx: Context, handler) {
  case wisp.get_cookie(req, "sid", wisp.Signed) {
    Ok(sid) ->
      case sessions.lookup_active(ctx.conn, sid) {
        Ok(user) -> handler(Context(..ctx, user: option.Some(user)))
        _ -> wisp.redirect("/login")
      }
    _ -> wisp.redirect("/login")
  }
}
