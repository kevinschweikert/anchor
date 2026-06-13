import lustre/attribute
import lustre/element/html

pub fn view() {
  html.html([], [
    html.head([], [
      html.title([], "Anchorage App"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/app.css"),
      ]),
      html.script(
        [attribute.type_("module"), attribute.src("/static/app.js")],
        "",
      ),
    ]),
    html.body([], [
      html.div([attribute.id("app")], []),
    ]),
  ])
}
