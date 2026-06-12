import lustre/attribute
import lustre/element/html

pub fn view() {
  html.html([], [
    html.head([], [
      html.title([], "Anchorage"),
    ]),
    html.body([], [
      html.form([attribute.method("post")], [
        html.input([attribute.type_("email"), attribute.name("email")]),
        html.input([attribute.type_("password"), attribute.name("password")]),
        html.input([attribute.type_("submit"), attribute.value("Login")]),
      ]),
    ]),
  ])
}
