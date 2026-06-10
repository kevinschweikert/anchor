import lustre
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub const tag_name = "anchor-widget"

pub fn main() -> Nil {
  let widget =
    lustre.component(init, update, view, [
      component.on_attribute_change("resource", fn(value) {
        Ok(ResourceChanged(value))
      }),
    ])
  let assert Ok(_) = lustre.register(widget, tag_name)

  Nil
}

type Model {
  Model(resource: String)
}

type Msg {
  ResourceChanged(String)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(resource: ""), effect.none())
}

fn update(_model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ResourceChanged(resource) -> #(Model(resource:), effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.text(
      "Hi from the booking widget for resource:" <> model.resource <> "!",
    ),
  ])
}
