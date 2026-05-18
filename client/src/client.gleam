import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

type Model {
  Model
}

type Msg {
  Msg
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model = Model
  #(model, effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [html.text("Hi from Lustre!")])
}
