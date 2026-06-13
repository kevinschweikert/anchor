import lustre/element
import lustre/element/html

pub fn view() -> element.Element(msg) {
  html.h1([], [html.text("Home")])
}
