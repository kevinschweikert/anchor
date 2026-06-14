import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type User}

pub fn loading() -> Element(msg) {
  html.span([attribute.class("loading loading-dots loading-lg")], [])
}

pub fn page(title: String, body: Element(msg)) {
  html.section([attribute.class("p-4")], [
    html.h1([], [html.text(title)]),
    body,
  ])
}

pub fn avatar(user: User) -> Element(msg) {
  let initials =
    user.name
    |> string.split(" ")
    |> list.map(fn(el) { el |> string.first |> result.unwrap("") })
    |> list.take(2)
    |> string.join("")

  html.div(
    [
      attribute.class("avatar avatar-placeholder"),
      attribute.role("button"),
      attribute.attribute("tabindex", "0"),
    ],
    [
      html.div(
        [
          attribute.class("bg-neutral text-neutral-content w-8 rounded-full"),
        ],
        [html.span([attribute.class("text-xs")], [html.text(initials)])],
      ),
    ],
  )
}

pub fn navbar(user: User, on_logout: msg) -> Element(msg) {
  html.div([attribute.class("navbar bg-neutral text-neutral-content")], [
    html.div([attribute.class("flex-1")], [
      html.a(
        [attribute.class("btn btn-ghost text-xl"), attribute.href("/admin")],
        [
          html.text("Anchor Admin"),
        ],
      ),
    ]),
    html.div([attribute.class("flex-none")], [
      html.ul([attribute.class("menu menu-horizontal px-1")], [
        html.li([], [
          html.a([attribute.href("/admin/bookings")], [html.text("Bookings")]),
        ]),
        html.li([], [
          html.a([attribute.href("/admin/spaces")], [
            html.text("Spaces"),
          ]),
        ]),
      ]),
    ]),
    html.div([attribute.class("dropdown dropdown-end")], [
      avatar(user),
      html.ul(
        [
          attribute.class(
            "menu menu-sm dropdown-content bg-neutral text-neutral-content rounded-box z-1 mt-3 w-52 p-2 shadow",
          ),
          attribute.attribute("tabindex", "-1"),
        ],
        [
          html.li([attribute.class("text-xs italic p-2")], [
            html.text(user.email),
          ]),
          html.li([], [
            html.button(
              [
                attribute.class("btn btn-ghost"),
                event.on_click(on_logout),
              ],
              [
                html.text("Logout"),
              ],
            ),
          ]),
        ],
      ),
    ]),
  ])
}

pub fn footer() -> Element(msg) {
  html.footer([], [])
}
