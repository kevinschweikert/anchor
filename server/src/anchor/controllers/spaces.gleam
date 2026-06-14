import anchor/spaces
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
    use new_space <- result.try(
      decode.run(json, shared.new_space_decoder())
      |> result.replace_error(shared.BadRequest),
    )
    use space <- result.try(
      spaces.create(ctx.conn, new_space)
      |> result.replace_error(shared.ServerError),
    )
    Ok(space)
  }

  case result {
    Ok(space) ->
      wisp.json_response(shared.space_to_json(space) |> json.to_string(), 201)
    Error(error) ->
      wisp.json_response(
        shared.api_error_to_json(error) |> json.to_string(),
        web.api_error_to_status_code(error),
      )
  }
}

pub fn show(id: String, ctx: Context) -> Response(wisp.Body) {
  case spaces.get(id, ctx.conn) {
    Ok(space) ->
      wisp.json_response(shared.space_to_json(space) |> json.to_string, 200)
    Error(_) -> wisp.not_found()
  }
}

pub fn index(ctx: Context) -> Response(wisp.Body) {
  let assert Ok(spaces) = spaces.list(ctx.conn)
  wisp.json_response(
    json.array(spaces, shared.space_to_json) |> json.to_string,
    200,
  )
}
