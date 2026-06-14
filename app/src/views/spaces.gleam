import gleam/bool
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import shared

pub fn view(spaces: List(shared.Space)) -> element.Element(msg) {
  html.div([attribute.class("flex flex-col gap-4")], {
    use space <- list.map(spaces)
    html.div([attribute.class("flex flex-row gap-4")], [
      html.h2([], [html.text(space.name)]),
      html.dl([], [
        html.dt([], [html.text("ID")]),
        html.dd([], [html.text(space.id)]),
        html.dt([], [html.text("Capacity")]),
        html.dd([], [
          html.text(space.capacity |> int.to_string()),
        ]),
        html.dt([], [html.text("Animals Allowed")]),
        html.dd([], [
          html.text(space.allow_animals |> bool.to_string()),
        ]),
      ]),
    ])
  })
}
