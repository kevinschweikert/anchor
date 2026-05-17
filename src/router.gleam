import gleam/http/request
import gleam/http/response
import gleam/json
import web
import wisp

pub fn handle_request(req) {
  use req <- web.middleware(req)
  // use json <- wisp.require_json(req)
  case wisp.path_segments(req) {
    [] -> home(req)
    _ -> wisp.not_found()
  }
}

fn home(
  _req: request.Request(wisp.Connection),
) -> response.Response(wisp.Body) {
  let payload = json.string("Work in progress")
  wisp.json_response(json.to_string(payload), 200)
}
