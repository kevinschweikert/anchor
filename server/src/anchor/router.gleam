import anchor/resource
import anchor/sessions
import anchor/users
import anchor/views/admin
import anchor/views/index
import anchor/views/login
import anchor/web.{type Context}
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/result
import lustre/element
import shared
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) {
  use req <- web.middleware(req, ctx)
  // use json <- wisp.require_json(req)
  case req.method, wisp.path_segments(req) {
    Get, [] -> serve_index(ctx)
    Get, ["login"] -> serve_login(req, ctx)
    Post, ["login"] -> handle_login(req, ctx)
    Post, ["logout"] -> handle_logout(req, ctx)
    Get, ["admin", ..] -> serve_admin(req, ctx)
    _, ["api", ..rest] -> handle_api_request(rest, req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn handle_api_request(
  rest: List(String),
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  case rest, req.method {
    ["me"], Get -> me_handler(req, ctx)
    ["resource"], Get -> list_resources_handler(ctx)
    ["resource", id], Get -> show_resource_handler(id, ctx)
    ["resource"], Post -> create_resource_handler(req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn me_handler(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  use user <- web.require_api_user(req, ctx)
  wisp.json_response(shared.user_to_json(user) |> json.to_string(), 200)
}

fn create_resource_handler(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  use _user <- web.require_api_user(req, ctx)
  use _json <- wisp.require_json(req)
  todo as "decode params and call resource.create_resource"
}

fn show_resource_handler(id: String, ctx: Context) -> Response(wisp.Body) {
  case resource.get_resource(id, ctx.conn) {
    Ok(resource) ->
      wisp.json_response(
        shared.resource_to_json(resource) |> json.to_string,
        200,
      )
    Error(_) -> wisp.not_found()
  }
}

fn list_resources_handler(ctx: Context) -> Response(wisp.Body) {
  let assert Ok(resources) = resource.list_resources(ctx.conn)
  wisp.json_response(
    json.array(resources, shared.resource_to_json) |> json.to_string,
    200,
  )
}

const ttl: Int = 2_592_000

fn handle_login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = sessions.delete_expired(ctx.conn)
  use form <- wisp.require_form(req)
  let result = {
    use email <- result.try(list.key_find(form.values, "email"))
    use password <- result.try(
      list.key_find(form.values, "password") |> result.replace_error(Nil),
    )
    use user <- result.try(users.authenticate(ctx.conn, email, password))
    use session_id <- result.try(
      sessions.insert(ctx.conn, wisp.random_string(32), user.id, ttl)
      |> result.replace_error(Nil),
    )
    Ok(session_id)
  }

  case result {
    Ok(session_id) ->
      wisp.redirect("/admin")
      |> wisp.set_cookie(req, "sid", session_id, wisp.Signed, 30 * 86_400)
    _ -> wisp.redirect("/login?error=1")
  }
}

fn handle_logout(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = case wisp.get_cookie(req, "sid", wisp.Signed) {
    Ok(sid) -> sessions.delete(ctx.conn, sid) |> result.replace_error(Nil)
    _ -> Ok(Nil)
  }

  wisp.redirect("/login")
  |> wisp.set_cookie(req, "sid", "", wisp.Signed, 0)
}

fn serve_index(_ctx: Context) -> Response(wisp.Body) {
  index.view()
  |> element.to_document_string
  |> wisp.html_response(200)
}

fn serve_login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  use <- web.redirect_if_authenticated("/admin", req, ctx)
  login.view()
  |> element.to_document_string
  |> wisp.html_response(200)
}

// The admin SPA owns everything under /admin, so any sub-path serves the same
// shell and routing happens client-side (modem).
fn serve_admin(req, ctx) -> Response(wisp.Body) {
  use _user <- web.require_user(req, ctx)

  admin.view()
  |> element.to_document_string
  |> wisp.html_response(200)
}
