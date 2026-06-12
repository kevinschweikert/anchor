import lustre/attribute
import lustre/element
import lustre/element/html

pub fn view() {
  html.html([], [
    html.head([], [
      html.title([], "Anchorage"),
      html.script(
        [attribute.type_("module"), attribute.src("/static/widget.js")],
        "",
      ),
    ]),
    html.body([], [
      element.element(
        "anchor-widget",
        [attribute.attribute("resource", "my-resource")],
        [],
      ),
    ]),
  ])
}
