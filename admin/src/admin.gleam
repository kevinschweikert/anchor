import gleam/option
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import rsvp
import shared

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Route {
  Bookings
  Resources
  NotFound
}

fn parse_route(route_uri: Uri) -> Route {
  case uri.path_segments(route_uri.path) {
    [] | ["admin"] -> Bookings
    ["admin", "resources"] -> Resources
    _ -> NotFound
  }
}

type Model {
  Model(route: Route, user: option.Option(shared.User))
}

type Msg {
  UserNavigatedTo(Route)
  ApiReturnedUser(Result(shared.User, rsvp.Error(String)))
}

fn fetch_me() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(shared.user_decoder(), ApiReturnedUser))
}

fn redirect_to_login() -> Effect(Msg) {
  let assert Ok(uri) = uri.parse("/login")
  modem.load(uri)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(route_uri) -> parse_route(route_uri)
    Error(_) -> Bookings
  }
  let on_url_change = fn(route_uri) { UserNavigatedTo(parse_route(route_uri)) }
  #(
    Model(route:, user: option.None),
    effect.batch([modem.init(on_url_change), fetch_me()]),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> #(Model(..model, route:), effect.none())
    ApiReturnedUser(Ok(user)) -> #(
      Model(..model, user: option.Some(user)),
      effect.none(),
    )
    ApiReturnedUser(Error(rsvp.HttpError(resp))) if resp.status == 401 -> #(
      model,
      redirect_to_login(),
    )
    ApiReturnedUser(Error(_)) -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.text(
      "hello "
      <> case model.user {
        option.Some(user) -> user.email
        option.None -> "..."
      },
    ),
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl")], [
          html.text("Anchor Admin"),
        ]),
      ]),
      html.div([attribute.class("flex-none")], [
        html.ul([attribute.class("menu menu-horizontal px-1")], [
          html.li([], [
            html.a([attribute.href("/admin")], [html.text("Bookings")]),
          ]),
          html.li([], [
            html.a([attribute.href("/admin/resources")], [
              html.text("Resources"),
            ]),
          ]),
        ]),
      ]),
    ]),

    case model.route {
      Bookings -> html.h1([], [html.text("Bookings")])
      Resources -> html.h1([], [html.text("Resources")])
      NotFound -> html.h1([], [html.text("Page not found")])
    },
    html.form([attribute.method("post"), attribute.action("/logout")], [
      html.input([attribute.type_("submit"), attribute.value("Logout")]),
    ]),
  ])
}
