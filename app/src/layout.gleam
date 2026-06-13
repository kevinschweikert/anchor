import components
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import shared

pub fn admin(
  slot: Element(msg),
  user: shared.User,
  on_logout: msg,
) -> Element(msg) {
  html.main([attribute.class("h-screen w-screen")], [
    components.navbar(user, on_logout),
    slot,
    components.footer(),
  ])
}
