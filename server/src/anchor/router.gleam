import anchor/resource
import anchor/sessions
import anchor/users
import anchor/views/app
import anchor/web.{type Context}
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import lustre/element
import shared
import wisp

const ttl: Int = 2_592_000

fn api_error_to_status_code(error: shared.ApiError) {
  case error {
    shared.BadRequest -> 400
    shared.BadCredentials -> 401
    shared.ServerError -> 500
  }
}

pub fn handle_request(req: wisp.Request, ctx: Context) {
  use req <- web.middleware(req, ctx)
  // use json <- wisp.require_json(req)
  case req.method, wisp.path_segments(req) {
    _, ["api", ..rest] -> handle_api_request(rest, req, ctx)
    Get, _ -> serve_lustre_app(req, ctx)
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
    ["login"], Post -> handle_login(req, ctx)
    ["logout"], Post -> handle_logout(req, ctx)
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

fn handle_login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = sessions.delete_expired(ctx.conn)
  use json <- wisp.require_json(req)
  let result = {
    use creds <- result.try(
      decode.run(json, shared.credentials_decoder())
      |> result.replace_error(shared.BadRequest),
    )
    use user <- result.try(
      users.authenticate(ctx.conn, creds.email, creds.password)
      |> result.replace_error(shared.BadCredentials),
    )
    use session_id <- result.try(
      sessions.insert(ctx.conn, wisp.random_string(32), user.id, ttl)
      |> result.replace_error(shared.ServerError),
    )
    Ok(#(session_id, user))
  }

  case result {
    Ok(#(session_id, user)) ->
      wisp.json_response(shared.user_to_json(user) |> json.to_string(), 200)
      |> wisp.set_cookie(req, "sid", session_id, wisp.Signed, ttl)
    Error(error) ->
      wisp.json_response(
        shared.api_error_to_json(error) |> json.to_string(),
        api_error_to_status_code(error),
      )
  }
}

fn handle_logout(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = case wisp.get_cookie(req, "sid", wisp.Signed) {
    Ok(sid) -> sessions.delete(ctx.conn, sid) |> result.replace_error(Nil)
    _ -> Ok(Nil)
  }

  wisp.json_response("{}", 200)
  |> wisp.set_cookie(req, "sid", "", wisp.Signed, 0)
}

fn serve_lustre_app(_req, _ctx) -> Response(wisp.Body) {
  app.view()
  |> element.to_document_string
  |> wisp.html_response(200)
}
