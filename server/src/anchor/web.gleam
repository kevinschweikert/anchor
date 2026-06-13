import anchor/sessions
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/result
import shared.{type User}
import sqlight
import wisp

pub type Context {
  Context(
    conn: sqlight.Connection,
    static_directory: String,
    trusted_origins: List(String),
  )
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  next: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- csrf_protection(req, ctx)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  next(req)
}

fn csrf_protection(
  req: request.Request(wisp.Connection),
  ctx: Context,
  next: fn(request.Request(wisp.Connection)) -> response.Response(wisp.Body),
) -> response.Response(wisp.Body) {
  case is_trusted_origin(req, ctx.trusted_origins) {
    True -> next(req)
    False -> wisp.csrf_known_header_protection(req, next)
  }
}

fn is_trusted_origin(
  req: request.Request(wisp.Connection),
  trusted_origins: List(String),
) -> Bool {
  case request.get_header(req, "origin") {
    Ok(origin) -> list.contains(trusted_origins, origin)
    Error(_) -> False
  }
}

fn session_user(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Result(User, Nil) {
  use sid <- result.try(wisp.get_cookie(req, "sid", wisp.Signed))
  use user <- result.try(
    sessions.lookup_active(ctx.conn, sid) |> result.replace_error(Nil),
  )
  Ok(user)
}

pub fn require_api_user(
  req: request.Request(wisp.Connection),
  ctx: Context,
  next: fn(User) -> response.Response(wisp.Body),
) -> response.Response(wisp.Body) {
  case session_user(req, ctx) {
    Ok(user) -> next(user)
    _ -> wisp.response(401)
  }
}
