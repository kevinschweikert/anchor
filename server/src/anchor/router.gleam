import anchor/controllers/resource
import anchor/controllers/session
import anchor/views/app
import anchor/web.{type Context}
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response.{type Response}
import lustre/element
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) {
  use req <- web.middleware(req, ctx)
  // use json <- wisp.require_json(req)
  case req.method, wisp.path_segments(req) {
    _, ["api", ..rest] -> handle_api_request(rest, req, ctx)
    Get, _ -> serve_lustre_app()
    _, _ -> wisp.not_found()
  }
}

fn handle_api_request(
  rest: List(String),
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  case rest, req.method {
    ["me"], Get -> session.me(req, ctx)
    ["login"], Post -> session.login(req, ctx)
    ["logout"], Post -> session.logout(req, ctx)
    ["resource"], Get -> resource.index(ctx)
    ["resource", id], Get -> resource.show(id, ctx)
    ["resource"], Post -> resource.create(req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn serve_lustre_app() -> Response(wisp.Body) {
  app.view()
  |> element.to_document_string
  |> wisp.html_response(200)
}
