import anchor/resource
import anchor/sessions
import anchor/users
import anchor/web.{type Context}
import argus
import gleam/bool
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import shared
import wisp
import youid/uuid

pub fn handle_request(req: wisp.Request, ctx: Context) {
  use req <- web.middleware(req, ctx)
  // use json <- wisp.require_json(req)
  case req.method, wisp.path_segments(req) {
    Get, [] -> serve_index(ctx)
    Get, ["login"] -> serve_login(req, ctx)
    Post, ["login"] -> handle_login(req, ctx)
    Post, ["logout"] -> handle_logout(req, ctx)
    Get, ["admin", ..] -> serve_admin(req, ctx)
    Get, ["api", ..rest] -> handle_api_request(rest, req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn handle_api_request(
  rest: List(String),
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  case rest, req.method {
    ["resource"], Get -> list_resources_handler(ctx)
    ["resource", id], Get -> show_resource_handler(id, ctx)
    ["resource"], Post -> create_resource_handler(req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn create_resource_handler(
  req: request.Request(wisp.Connection),
  _ctx: Context,
) -> Response(wisp.Body) {
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

fn handle_login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = sessions.delete_expired(ctx.conn)
  use form <- wisp.require_form(req)
  let result = {
    use email <- result.try(list.key_find(form.values, "email"))
    use password <- result.try(
      list.key_find(form.values, "password") |> result.replace_error(Nil),
    )
    use user <- result.try(
      users.get_by_email(ctx.conn, email) |> result.replace_error(Nil),
    )
    use maybe_verified <- result.try(
      argus.verify(user.password_hash, password) |> result.replace_error(Nil),
    )
    use <- bool.guard(when: maybe_verified == False, return: Error(Nil))
    use session_id <- result.try(
      sessions.insert(
        ctx.conn,
        wisp.random_string(32),
        user.id |> uuid.to_string(),
        30 * 86_400,
      )
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
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Anchorage"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/widget.js")],
          "",
        ),
      ]),
      html.body([], [
        element.element(
          "anchor-widget",
          [attribute.attribute("resource", "my-resource")],
          [],
        ),
      ]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}

fn serve_login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Anchorage"),
      ]),
      html.body([], [
        html.form([attribute.method("post")], [
          html.input([attribute.type_("email"), attribute.name("email")]),
          html.input([attribute.type_("password"), attribute.name("password")]),
          html.input([attribute.type_("submit"), attribute.value("Login")]),
        ]),
      ]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}

// The admin SPA owns everything under /admin, so any sub-path serves the same
// shell and routing happens client-side (modem).
fn serve_admin(req, ctx) -> Response(wisp.Body) {
  use ctx <- web.require_admin(req, ctx)

  let name = case ctx.user {
    option.Some(user) -> user.email
    _ -> "unknown"
  }
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Anchorage Admin"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/admin.js")],
          "",
        ),
      ]),
      html.body([], [
        html.text("Hello " <> name),
        html.div([attribute.id("app")], []),
        html.form([attribute.method("post"), attribute.action("/logout")], [
          html.input([attribute.type_("submit"), attribute.value("Logout")]),
        ]),
      ]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}
