import anchor/resource
import anchor/web.{type Context}
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import lustre/attribute
import lustre/element
import lustre/element/html
import shared
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) {
  use req <- web.middleware(req, ctx)
  // use json <- wisp.require_json(req)
  case req.method, wisp.path_segments(req) {
    Get, [] -> serve_landing()
    Get, ["demo"] -> serve_widget_demo()
    Get, ["admin", ..] -> serve_admin()
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

fn serve_landing() -> Response(wisp.Body) {
  let html =
    html.html([], [
      html.head([], [html.title([], "Anchorage")]),
      html.body([], [
        html.h1([], [html.text("Anchorage")]),
        html.p([], [html.text("Simple bookings for your resources.")]),
        html.ul([], [
          html.li([], [
            html.a([attribute.href("/demo")], [html.text("Widget demo")]),
          ]),
          html.li([], [
            html.a([attribute.href("/admin")], [html.text("Admin")]),
          ]),
        ]),
      ]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}

fn serve_widget_demo() -> Response(wisp.Body) {
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Anchorage Widget Demo"),
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

// The admin SPA owns everything under /admin, so any sub-path serves the same
// shell and routing happens client-side (modem).
fn serve_admin() -> Response(wisp.Body) {
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
        html.div([attribute.id("app")], []),
      ]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}
