import app
import gleeunit
import lustre/dev/query
import lustre/dev/simulate

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn app_boots_and_renders_home_test() {
  let view =
    simulate.application(init: app.init, update: app.update, view: app.view)
    |> simulate.start(Nil)
    |> simulate.view()

  assert query.has(in: view, matching: query.text("Home"))
}
