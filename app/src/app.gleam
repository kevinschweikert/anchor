import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared.{type Resource, type User}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Route {
  Public(PublicRoute)
  Admin(AdminRoute)
  Guest(GuestRoute)
}

type PublicRoute {
  Home
  NotFound
}

type AdminRoute {
  Dashboard
  Bookings
  Resources
}

type GuestRoute {
  Login
}

type Auth {
  Checking
  Authenticated(User)
  Anonymous
}

type Remote(a) {
  Loading
  Loaded(a)
  Failed
}

fn parse_route(route_uri: Uri) -> Route {
  case uri.path_segments(route_uri.path) {
    [] -> Public(Home)
    ["login"] -> Guest(Login)
    ["admin"] -> Admin(Dashboard)
    ["admin", "bookings"] -> Admin(Bookings)
    ["admin", "resources"] -> Admin(Resources)
    _ -> Public(NotFound)
  }
}

type Model {
  Model(
    route: Route,
    auth: Auth,
    login_error: Option(String),
    resources: Remote(List(Resource)),
  )
}

type Msg {
  UserNavigatedTo(Route)
  UserSubmittedLogin(List(#(String, String)))
  UserClickedLogout
  ApiReturnedUser(Result(User, rsvp.Error(String)))
  ApiReturnedLogin(Result(User, rsvp.Error(String)))
  ApiReturnedLogout
  ApiReturnedResources(Result(List(Resource), rsvp.Error(String)))
}

fn fetch_me() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(shared.user_decoder(), ApiReturnedUser))
}

fn fetch_for_route(route: Route) -> Effect(Msg) {
  case route {
    Admin(Resources) -> fetch_resources()
    _ -> effect.none()
  }
}

fn fetch_resources() -> Effect(Msg) {
  rsvp.get(
    "/api/resource",
    rsvp.expect_json(
      decode.list(shared.resource_decoder()),
      ApiReturnedResources,
    ),
  )
}

fn post_login(email: String, password: String) -> Effect(Msg) {
  rsvp.post(
    "/api/login",
    shared.Credentials(email:, password:) |> shared.credentials_to_json(),
    rsvp.expect_json(shared.user_decoder(), ApiReturnedLogin),
  )
}

fn post_logout() -> Effect(Msg) {
  rsvp.post(
    "/api/logout",
    json.object([]),
    rsvp.expect_ok_response(fn(_) { ApiReturnedLogout }),
  )
}

fn middleware(state: #(Model, Effect(Msg))) -> #(Model, Effect(Msg)) {
  let #(model, effect) = state
  #(model, effect.batch([effect, redirect(model.route, model.auth)]))
}

fn redirect(route: Route, auth: Auth) -> Effect(Msg) {
  case route, auth {
    _, Checking -> effect.none()
    Admin(_), Anonymous -> modem.push("/login", None, None)
    Guest(_), Authenticated(_) -> modem.push("/admin", None, None)
    _, _ -> effect.none()
  }
}

fn init(_: a) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(route_uri) -> parse_route(route_uri)
    Error(_) -> Public(Home)
  }
  let on_url_change = fn(route_uri) { UserNavigatedTo(parse_route(route_uri)) }
  #(
    Model(route:, auth: Checking, login_error: None, resources: Loading),
    effect.batch([modem.init(on_url_change), fetch_me(), fetch_for_route(route)]),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> {
      #(Model(..model, route:), fetch_for_route(route))
    }
    UserSubmittedLogin(fields) -> {
      let email = list.key_find(fields, "email") |> result.unwrap("")
      let password = list.key_find(fields, "password") |> result.unwrap("")
      #(Model(..model, login_error: None), post_login(email, password))
    }
    UserClickedLogout -> #(model, post_logout())
    ApiReturnedLogin(Ok(user)) -> #(
      Model(..model, auth: Authenticated(user), login_error: None),
      effect.none(),
    )

    ApiReturnedLogin(Error(rsvp.HttpError(resp))) -> {
      let text = case json.parse(resp.body, shared.api_error_decoder()) {
        Ok(shared.BadCredentials) -> "Invalid email or password"
        Ok(shared.BadRequest) -> "Please check your input and try again"
        Ok(shared.ServerError) | Error(_) ->
          "Something went wrong. Please try again"
      }
      #(Model(..model, auth: Anonymous, login_error: Some(text)), effect.none())
    }
    ApiReturnedLogin(Error(_)) -> #(
      Model(
        ..model,
        auth: Anonymous,
        login_error: Some("Couldn't reach the server. Try again"),
      ),
      effect.none(),
    )

    ApiReturnedLogout -> #(Model(..model, auth: Anonymous), effect.none())
    ApiReturnedUser(Ok(user)) -> #(
      Model(..model, auth: Authenticated(user)),
      effect.none(),
    )
    ApiReturnedUser(Error(_)) -> #(
      Model(..model, auth: Anonymous),
      effect.none(),
    )
    ApiReturnedResources(Ok(resources)) -> #(
      Model(..model, resources: Loaded(resources)),
      effect.none(),
    )
    ApiReturnedResources(Error(_)) -> #(
      Model(..model, resources: Failed),
      effect.none(),
    )
  }
  |> middleware()
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    case model.route, model.auth {
      Admin(admin_route), Authenticated(user) ->
        admin_view(user, admin_route, model)
      Admin(_), _ -> loading_view()
      Public(Home), _ -> html.h1([], [html.text("Home")])
      Guest(Login), _ -> login_view(model)
      Public(NotFound), _ -> html.h1([], [html.text("Page not found")])
    },
  ])
}

fn loading_view() -> Element(Msg) {
  html.h1([], [html.text("loading")])
}

fn login_view(model: Model) -> Element(Msg) {
  html.div([], [
    case model.login_error {
      Some(text) ->
        html.p([attribute.class("p-2 bg-red-400 rounded")], [html.text(text)])
      None -> element.none()
    },
    html.form(
      [
        event.on_submit(UserSubmittedLogin),
        attribute.class("flex flex-col gap-4"),
      ],
      [
        html.label([], [
          html.text("Email address"),
          html.input([
            attribute.autocomplete("email"),
            attribute.required(True),
            attribute.name("email"),
            attribute.type_("email"),
            attribute.id("email"),
          ]),
        ]),
        html.label([], [
          html.text("Password"),
          html.input([
            attribute.autocomplete("current-password"),
            attribute.required(True),
            attribute.name("password"),
            attribute.type_("password"),
            attribute.id("password"),
          ]),
        ]),
        html.input([
          attribute.value("Sign In"),
          attribute.type_("submit"),
        ]),
      ],
    ),
  ])
}

fn admin_view(user: User, route: AdminRoute, model: Model) -> Element(Msg) {
  html.div([], [
    html.text("hello " <> user.email),
    html.button([event.on_click(UserClickedLogout)], [html.text("Logout")]),
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl")], [
          html.text("Anchor Admin"),
        ]),
      ]),
      html.div([attribute.class("flex-none")], [
        html.ul([attribute.class("menu menu-horizontal px-1")], [
          html.li([], [
            html.a([attribute.href("/admin/bookings")], [html.text("Bookings")]),
          ]),
          html.li([], [
            html.a([attribute.href("/admin/resources")], [
              html.text("Resources"),
            ]),
          ]),
        ]),
      ]),
    ]),
    case route {
      Dashboard -> html.text("dashboard")
      Bookings -> html.text("bookings")
      Resources ->
        case model.resources {
          Loaded(resources) -> {
            html.div([attribute.class("flex flex-col gap-4")], {
              use resource <- list.map(resources)
              html.div([attribute.class("flex flex-row gap-4")], [
                html.h2([], [html.text(resource.name)]),
                html.dl([], [
                  html.dt([], [html.text("ID")]),
                  html.dd([], [html.text(resource.id)]),
                  html.dt([], [html.text("Capacity")]),
                  html.dd([], [html.text(resource.capacity |> int.to_string())]),
                  html.dt([], [html.text("Animals Allowed")]),
                  html.dd([], [
                    html.text(resource.allow_animals |> bool.to_string()),
                  ]),
                ]),
              ])
            })
          }
          Loading -> html.text("loading resources")
          Failed -> html.text("loading resources failed")
        }
    },
  ])
}
