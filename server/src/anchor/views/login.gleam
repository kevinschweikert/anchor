import lustre/attribute
import lustre/element/html

pub fn view() {
  html.html([attribute.class("h-full bg-gray-900")], [
    html.head([], [
      html.title([], "Anchorage"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/admin.css"),
      ]),
    ]),
    html.body([attribute.class("h-full")], [
      html.div(
        [
          attribute.class(
            "flex min-h-full flex-col justify-center px-6 py-12 lg:px-8",
          ),
        ],
        [
          html.div([attribute.class("sm:mx-auto sm:w-full sm:max-w-sm")], [
            html.h2(
              [
                attribute.class(
                  "mt-10 text-center text-2xl/9 font-bold tracking-tight text-white",
                ),
              ],
              [html.text("Sign in to your account")],
            ),
          ]),
          html.div([attribute.class("mt-10 sm:mx-auto sm:w-full sm:max-w-sm")], [
            html.form(
              [
                attribute.class("space-y-6"),
                attribute.method("POST"),
              ],
              [
                html.div([], [
                  html.label(
                    [
                      attribute.class(
                        "block text-sm/6 font-medium text-gray-100",
                      ),
                      attribute.for("email"),
                    ],
                    [html.text("Email address")],
                  ),
                  html.div([attribute.class("mt-2")], [
                    html.input([
                      attribute.class(
                        "block w-full rounded-md bg-white/5 px-3 py-1.5 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-gray-500 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-500 sm:text-sm/6",
                      ),
                      attribute.autocomplete("email"),
                      attribute.required(True),
                      attribute.name("email"),
                      attribute.type_("email"),
                      attribute.id("email"),
                    ]),
                  ]),
                ]),
                html.div([], [
                  html.div([attribute.class("mt-2")], [
                    html.input([
                      attribute.class(
                        "block w-full rounded-md bg-white/5 px-3 py-1.5 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-gray-500 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-500 sm:text-sm/6",
                      ),
                      attribute.autocomplete("current-password"),
                      attribute.required(True),
                      attribute.name("password"),
                      attribute.type_("password"),
                      attribute.id("password"),
                    ]),
                  ]),
                ]),
                html.div([], [
                  html.input([
                    attribute.class(
                      "flex w-full justify-center rounded-md bg-indigo-500 px-3 py-1.5 text-sm/6 font-semibold text-white hover:bg-indigo-400 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500",
                    ),
                    attribute.value("Sign In"),
                    attribute.type_("submit"),
                  ]),
                ]),
              ],
            ),
          ]),
        ],
      ),
    ]),
  ])
}
