import anchor/resource
import anchor/web.{type Context}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import shared
import wisp

pub fn create(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  use _user <- web.require_api_user(req, ctx)
  use _json <- wisp.require_json(req)
  todo as "decode params and call resource.create_resource"
}

pub fn show(id: String, ctx: Context) -> Response(wisp.Body) {
  case resource.get_resource(id, ctx.conn) {
    Ok(resource) ->
      wisp.json_response(
        shared.resource_to_json(resource) |> json.to_string,
        200,
      )
    Error(_) -> wisp.not_found()
  }
}

pub fn index(ctx: Context) -> Response(wisp.Body) {
  let assert Ok(resources) = resource.list_resources(ctx.conn)
  wisp.json_response(
    json.array(resources, shared.resource_to_json) |> json.to_string,
    200,
  )
}
