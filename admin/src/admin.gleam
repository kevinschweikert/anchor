import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem

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
  Model(route: Route)
}

type Msg {
  UserNavigatedTo(Route)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(route_uri) -> parse_route(route_uri)
    Error(_) -> Bookings
  }
  let on_url_change = fn(route_uri) { UserNavigatedTo(parse_route(route_uri)) }
  #(Model(route:), modem.init(on_url_change))
}

fn update(_model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> #(Model(route:), effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.nav([], [
      html.a([attribute.href("/admin")], [html.text("Bookings")]),
      html.text(" | "),
      html.a([attribute.href("/admin/resources")], [html.text("Resources")]),
    ]),
    case model.route {
      Bookings -> html.h1([], [html.text("Bookings")])
      Resources -> html.h1([], [html.text("Resources")])
      NotFound -> html.h1([], [html.text("Page not found")])
    },
  ])
}
