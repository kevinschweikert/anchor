import components
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import layout
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import rsvp
import shared.{type Space, type User}
import views/home
import views/login
import views/not_found
import views/spaces

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub type Route {
  Public(PublicRoute)
  Admin(AdminRoute)
  Guest(GuestRoute)
}

pub type PublicRoute {
  Home
  NotFound
}

pub type AdminRoute {
  Dashboard
  Bookings
  Spaces
}

pub type GuestRoute {
  Login
}

pub type Auth {
  Checking
  Authenticated(User)
  Anonymous
}

pub type Remote(a) {
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
    ["admin", "spaces"] -> Admin(Spaces)
    _ -> Public(NotFound)
  }
}

pub type Model {
  Model(
    route: Route,
    auth: Auth,
    login_error: Option(String),
    spaces: Remote(List(Space)),
  )
}

pub type Msg {
  UserNavigatedTo(Route)
  UserSubmittedLogin(List(#(String, String)))
  UserClickedLogout
  ApiReturnedUser(Result(User, rsvp.Error(String)))
  ApiReturnedLogin(Result(User, rsvp.Error(String)))
  ApiReturnedLogout
  ApiReturnedSpaces(Result(List(Space), rsvp.Error(String)))
}

fn fetch_me() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(shared.user_decoder(), ApiReturnedUser))
}

fn fetch_for_route(route: Route) -> Effect(Msg) {
  case route {
    Admin(Spaces) -> fetch_spaces()
    _ -> effect.none()
  }
}

fn fetch_spaces() -> Effect(Msg) {
  rsvp.get(
    "/api/spaces",
    rsvp.expect_json(decode.list(shared.space_decoder()), ApiReturnedSpaces),
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

fn handle_api_error(model, err, otherwise: fn() -> #(Model, Effect(Msg))) {
  case err {
    rsvp.HttpError(resp) if resp.status == 401 -> {
      #(Model(..model, auth: Anonymous), effect.none())
    }
    _ -> otherwise()
  }
}

pub fn init(_: a) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(route_uri) -> parse_route(route_uri)
    Error(_) -> Public(Home)
  }
  let on_url_change = fn(route_uri) { UserNavigatedTo(parse_route(route_uri)) }
  #(
    Model(route:, auth: Checking, login_error: None, spaces: Loading),
    effect.batch([modem.init(on_url_change), fetch_me(), fetch_for_route(route)]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
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
    ApiReturnedUser(Error(error)) -> {
      use <- handle_api_error(model, error)
      #(Model(..model, auth: Anonymous), effect.none())
    }
    ApiReturnedSpaces(Ok(spaces)) -> #(
      Model(..model, spaces: Loaded(spaces)),
      effect.none(),
    )
    ApiReturnedSpaces(Error(error)) -> {
      use <- handle_api_error(model, error)
      #(Model(..model, spaces: Failed), effect.none())
    }
  }
  |> middleware()
}

pub fn view(model: Model) -> Element(Msg) {
  element.fragment([
    case model.route, model.auth {
      Admin(admin_route), Authenticated(user) ->
        admin_pages(admin_route, model)
        |> layout.admin(user, UserClickedLogout)
      Admin(_), _ -> components.loading()
      Public(Home), _ -> home.view()
      Guest(Login), _ -> login.view(model.login_error, UserSubmittedLogin)
      Public(NotFound), _ -> not_found.view()
    },
  ])
}

fn admin_pages(route: AdminRoute, model: Model) -> Element(Msg) {
  case route {
    Dashboard -> components.page("Home", element.none())
    Bookings -> components.page("Bookings", element.none())
    Spaces ->
      case model.spaces {
        Loaded(items) -> spaces.view(items)
        Loading -> components.loading()
        Failed -> html.text("loading spaces failed")
      }
      |> components.page("Spaces", _)
  }
}
