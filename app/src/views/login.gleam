import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(
  error: option.Option(String),
  on_submit: fn(List(#(String, String))) -> msg,
) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "h-screen w-screen flex flex-col items-center justify-center",
      ),
    ],
    [
      html.h1([], [html.text("Anchor Admin")]),
      html.form(
        [
          event.on_submit(on_submit),
          attribute.class("flex flex-col gap-4  items-center"),
        ],
        [
          html.fieldset(
            [attribute.class("fieldset w-md bg-base-200 p-4 rounded-box")],
            [
              html.legend([attribute.class("fieldset-legend")], [
                html.text("Login"),
              ]),
              html.label([], [
                html.text("Email address"),
              ]),
              html.input([
                attribute.class("input w-full"),
                attribute.autocomplete("email"),
                attribute.required(True),
                attribute.name("email"),
                attribute.type_("email"),
                attribute.id("email"),
              ]),
              html.label([], [
                html.text("Password"),
              ]),
              html.input([
                attribute.class("input w-full"),
                attribute.autocomplete("current-password"),
                attribute.required(True),
                attribute.name("password"),
                attribute.type_("password"),
                attribute.id("password"),
              ]),
              case error {
                Some(text) ->
                  html.p([attribute.class("w-full p-2 bg-red-400 rounded")], [
                    html.text(text),
                  ])
                None -> element.none()
              },
              html.input([
                attribute.class("btn btn-neutral w-full"),
                attribute.value("Sign In"),
                attribute.type_("submit"),
              ]),
            ],
          ),
        ],
      ),
    ],
  )
}
