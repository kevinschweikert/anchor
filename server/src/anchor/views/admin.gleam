import lustre/attribute
import lustre/element/html

pub fn view() {
  html.html([], [
    html.head([], [
      html.title([], "Anchorage Admin"),
      html.script(
        [attribute.type_("module"), attribute.src("/static/admin.js")],
        "",
      ),
    ]),
    html.body([], [
      html.div([attribute.id("app")], []),
    ]),
  ])
}
