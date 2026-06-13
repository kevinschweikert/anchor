import anchor/sessions
import anchor/users
import anchor/web.{type Context}
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import shared
import wisp

const ttl: Int = 2_592_000

pub fn me(
  req: request.Request(wisp.Connection),
  ctx: Context,
) -> Response(wisp.Body) {
  use user <- web.require_api_user(req, ctx)
  wisp.json_response(shared.user_to_json(user) |> json.to_string(), 200)
}

pub fn login(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
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
        web.api_error_to_status_code(error),
      )
  }
}

pub fn logout(req: wisp.Request, ctx: Context) -> Response(wisp.Body) {
  let _ = case wisp.get_cookie(req, "sid", wisp.Signed) {
    Ok(sid) -> sessions.delete(ctx.conn, sid) |> result.replace_error(Nil)
    _ -> Ok(Nil)
  }

  wisp.json_response("{}", 200)
  |> wisp.set_cookie(req, "sid", "", wisp.Signed, 0)
}
