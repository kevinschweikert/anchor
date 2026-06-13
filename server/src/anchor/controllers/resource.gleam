import anchor/resource
import anchor/web.{type Context}
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import shared
import wisp

pub fn create(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  use _user <- web.require_api_user(req, ctx)
  use json <- wisp.require_json(req)
  let result = {
    use new_resource <- result.try(
      decode.run(json, shared.new_resource_decoder())
      |> result.replace_error(shared.BadRequest),
    )
    use resource <- result.try(
      resource.create_resource(ctx.conn, new_resource)
      |> result.replace_error(shared.ServerError),
    )
    Ok(resource)
  }

  case result {
    Ok(resource) ->
      wisp.json_response(
        shared.resource_to_json(resource) |> json.to_string(),
        201,
      )
    Error(error) ->
      wisp.json_response(
        shared.api_error_to_json(error) |> json.to_string(),
        web.api_error_to_status_code(error),
      )
  }
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
