import gleam/http/request.{type Request}
import gleam/http/response
import gleam/json
import gleam/list
import resource
import web.{type Context, Context}
import wisp.{type Connection}

pub fn handle_request(req: wisp.Request, context: Context) {
  use req <- web.middleware(req)
  // use json <- wisp.require_json(req)
  case wisp.path_segments(req) {
    [] -> home(req, context)
    _ -> wisp.not_found()
  }
}

fn home(
  _req: Request(Connection),
  context: Context,
) -> response.Response(wisp.Body) {
  let Context(conn:) = context
  case resource.list_resources(conn) {
    Ok(resources) -> {
      let resources = list.map(resources, resource.to_json)
      let payload = json.preprocessed_array(resources)
      wisp.json_response(json.to_string(payload), 200)
    }
    _ -> wisp.json_response("internal server error", 500)
  }
}
