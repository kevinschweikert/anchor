import gleam/bool
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import shared

pub fn view(resources: List(shared.Resource)) -> element.Element(msg) {
  html.div([attribute.class("flex flex-col gap-4")], {
    use resource <- list.map(resources)
    html.div([attribute.class("flex flex-row gap-4")], [
      html.h2([], [html.text(resource.name)]),
      html.dl([], [
        html.dt([], [html.text("ID")]),
        html.dd([], [html.text(resource.id)]),
        html.dt([], [html.text("Capacity")]),
        html.dd([], [
          html.text(resource.capacity |> int.to_string()),
        ]),
        html.dt([], [html.text("Animals Allowed")]),
        html.dd([], [
          html.text(resource.allow_animals |> bool.to_string()),
        ]),
      ]),
    ])
  })
}
