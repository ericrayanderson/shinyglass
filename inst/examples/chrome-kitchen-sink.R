# Overlay / chrome kitchen sink for shinyglass.
#
# Exercises surfaces that only exist after a click, plus page functions the
# package advertises but no other example uses: page_navbar, nav_menu,
# accordion, tooltip/popover, input_switch, datepicker popup, server modal,
# notification types, file Browse, native multi-select, inline checks.
#
# Run:
#   shiny::runApp(system.file("examples", "chrome-kitchen-sink.R", package = "shinyglass"))
#
# Dark preset:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "chrome-kitchen-sink.R", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (is.character(x) && !nzchar(x[[1]]))) y else x
}

bslib_has <- function(fn) {
  exists(fn, envir = asNamespace("bslib"), inherits = FALSE)
}

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "auto"),
  c("light", "dark", "auto")
)

maybe <- function(ok, expr) {
  if (isTRUE(ok)) expr else NULL
}

tooltip_ui <- maybe(bslib_has("tooltip"), {
  tooltip(
    actionButton("tip_btn", "Hover tooltip", class = "btn-outline-primary"),
    "Tooltip on glass"
  )
})

popover_ui <- maybe(bslib_has("popover"), {
  popover(
    actionButton("pop_btn", "Open popover", class = "btn-outline-primary"),
    title = "Popover",
    "Popover body on the glass menu surface."
  )
})

switch_ui <- maybe(bslib_has("input_switch"), {
  input_switch("sw", "input_switch", value = TRUE)
})

accordion_ui <- maybe(bslib_has("accordion") && bslib_has("accordion_panel"), {
  accordion(
    id = "acc",
    open = "One",
    accordion_panel("One", "First accordion panel — glass header + body."),
    accordion_panel("Two", "Second accordion panel opened by the contrast audit.")
  )
})

navsets_ui <- tagList(
  if (bslib_has("navset_pill")) {
    navset_pill(
      nav_panel("Pill A", p("navset_pill panel A")),
      nav_panel("Pill B", p("navset_pill panel B"))
    )
  },
  tags$hr(),
  if (bslib_has("navset_underline")) {
    navset_underline(
      nav_panel("Under A", p("navset_underline panel A")),
      nav_panel("Under B", p("navset_underline panel B"))
    )
  }
)

ui <- page_navbar(
  title = "Glass chrome",
  id = "nav",
  theme = glass_theme(preset = glass_preset),
  fillable = FALSE,
  nav_panel(
    "Overlays",
    layout_column_wrap(
      width = "16rem",
      heights_equal = "row",
      gap = "0.75rem",
      card(
        card_header("Dates"),
        dateInput("date", "dateInput", value = Sys.Date(), width = "100%"),
        dateRangeInput(
          "date_range",
          "dateRangeInput",
          start = Sys.Date() - 7,
          end = Sys.Date(),
          width = "100%"
        )
      ),
      card(
        card_header("File"),
        fileInput("file", "fileInput", accept = c(".txt", ".csv"), width = "100%")
      ),
      card(
        card_header("Notifications"),
        div(
          class = "d-flex flex-wrap gap-2",
          actionButton("notify_default", "default"),
          actionButton("notify_message", "message", class = "btn-primary"),
          actionButton("notify_warning", "warning", class = "btn-warning"),
          actionButton("notify_error", "error", class = "btn-danger")
        )
      ),
      card(
        card_header("Server modal"),
        actionButton("show_server_modal", "showModal()", class = "btn-outline-primary"),
        div(
          class = "mt-2 d-flex flex-wrap gap-2 align-items-center",
          actionButton("disabled_btn", "Disabled", class = "btn-secondary", disabled = TRUE),
          tags$button(
            type = "button",
            class = "btn-close",
            id = "lone_close",
            `aria-label` = "Close"
          )
        )
      )
    )
  ),
  nav_panel(
    "bslib",
    layout_column_wrap(
      width = "16rem",
      heights_equal = "row",
      gap = "0.75rem",
      card(
        card_header("Accordion"),
        accordion_ui %||% p(class = "text-muted", "bslib::accordion() not available.")
      ),
      card(
        card_header("Tooltip / popover / switch"),
        div(class = "d-flex flex-wrap gap-2 mb-2", tooltip_ui, popover_ui),
        switch_ui %||% p(class = "text-muted", "input_switch() not available.")
      ),
      card(
        card_header("Navsets"),
        navsets_ui
      )
    )
  ),
  nav_menu(
    title = "More",
    nav_panel(
      "Selects",
      layout_column_wrap(
        width = "16rem",
        card(
          card_header("Native multi + inline"),
          selectInput(
            "multi",
            "selectInput(multiple, selectize = FALSE)",
            letters[1:8],
            selected = c("a", "c"),
            multiple = TRUE,
            selectize = FALSE,
            width = "100%"
          ),
          checkboxGroupInput(
            "inline_cb",
            "inline checkboxGroup",
            c("Email", "SMS", "Push"),
            selected = "Email",
            inline = TRUE
          ),
          radioButtons(
            "inline_radio",
            "inline radio",
            c("S", "M", "L"),
            selected = "M",
            inline = TRUE
          )
        ),
        card(
          card_header("Classic well"),
          wellPanel(
            p("wellPanel under glass_theme()."),
            sliderInput("well_n", "n", 1, 10, 4, width = "100%")
          )
        )
      )
    )
  ),
  nav_spacer(),
  nav_item(glass_theme_toggle(selected = glass_preset))
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)

  notify <- function(type) {
    observeEvent(input[[paste0("notify_", type)]], {
      showNotification(
        paste("Notification type:", type),
        type = type,
        duration = 4
      )
    }, ignoreInit = TRUE)
  }
  notify("default")
  notify("message")
  notify("warning")
  notify("error")

  observeEvent(input$show_server_modal, {
    showModal(modalDialog(
      title = "Server modalDialog",
      easyClose = TRUE,
      footer = tagList(
        modalButton("Cancel"),
        actionButton("modal_ok", "OK", class = "btn-primary")
      ),
      selectInput(
        "modal_choice",
        "Choice",
        c("Ultra Clear", "Balanced", "Tinted"),
        selected = "Balanced",
        width = "100%"
      ),
      textInput("modal_text", "Note", "Hello from showModal()", width = "100%")
    ))
  }, ignoreInit = TRUE)

  observeEvent(input$modal_ok, {
    removeModal()
    showNotification(
      paste0("Modal OK — ", input$modal_choice %||% "?", " / ", input$modal_text %||% ""),
      type = "message",
      duration = 3
    )
  }, ignoreInit = TRUE)
}

shinyApp(ui, server)
