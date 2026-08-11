# Showcase every standard Shiny input with shinyglass.
#
# Run:
#   shiny::runApp(system.file("examples", "inputs-gallery.R", package = "shinyglass"))
#
# Dark preset:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "inputs-gallery.R", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (is.character(x) && !nzchar(x[[1]]))) y else x
}

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "auto"),
  c("light", "dark", "auto")
)

ui <- page_sidebar(
  title = "Shiny Inputs Gallery",
  theme = glass_theme(preset = glass_preset),
  fillable = TRUE,
  sidebar = sidebar(
    title = "About",
    width = 280,
    open = "desktop",
    p(
      class = "text-muted",
      "Every built-in Shiny input and button, styled with ",
      code("glass_theme()"), ". Change controls — values update live below."
    ),
    glass_preset_input(
      "preset",
      label = "Theme preset",
      selected = glass_preset,
      width = "100%"
    ),
    tags$hr(),
    tags$small(
      class = "text-muted",
      "Sidebar starts closed on phones; use the toggle to open filters."
    )
  ),
  # Stack cards on phones (min ~16rem) instead of fixed 50/50 columns
  layout_column_wrap(
    width = "16rem",
    heights_equal = "row",
    gap = "0.75rem",
    card(
      card_header("Text & numbers"),
      textInput("text", "textInput", "Hello glass", width = "100%"),
      passwordInput("password", "passwordInput", "secret", width = "100%"),
      textAreaInput("textarea", "textAreaInput", "Multi-line\ntext", rows = 3, width = "100%"),
      numericInput("numeric", "numericInput", 42, min = 0, max = 100, width = "100%")
    ),
    card(
      card_header("Slider"),
      sliderInput("slider", "sliderInput", 0, 100, 50, step = 5, width = "100%"),
      sliderInput(
        "slider_range",
        "sliderInput (range)",
        min = 0,
        max = 100,
        value = c(25, 75),
        width = "100%"
      )
    ),
    card(
      card_header("Select menus"),
      selectInput(
        "select",
        "selectInput",
        c("Apple" = "apple", "Banana" = "banana", "Cherry" = "cherry"),
        selected = "banana",
        width = "100%"
      ),
      selectizeInput(
        "selectize",
        "selectizeInput",
        c("Red" = "red", "Green" = "green", "Blue" = "blue"),
        selected = "blue",
        multiple = TRUE,
        width = "100%"
      ),
      selectizeInput(
        "selectize_single",
        "selectizeInput (single)",
        state.name,
        selected = "California",
        width = "100%"
      )
    ),
    card(
      card_header("Checkboxes & radios"),
      checkboxInput("checkbox", "checkboxInput", TRUE),
      checkboxGroupInput(
        "checkbox_group",
        "checkboxGroupInput",
        c("Email" = "email", "SMS" = "sms", "Push" = "push"),
        selected = c("email", "push"),
        inline = FALSE
      ),
      radioButtons(
        "radio",
        "radioButtons",
        c("Small" = "sm", "Medium" = "md", "Large" = "lg"),
        selected = "md",
        inline = FALSE
      )
    ),
    card(
      card_header("Variable selectors"),
      varSelectInput("var_select", "varSelectInput", mtcars, selected = "mpg", width = "100%"),
      varSelectizeInput(
        "var_selectize",
        "varSelectizeInput",
        iris,
        selected = "Species",
        multiple = TRUE,
        width = "100%"
      )
    ),
    card(
      card_header("Dates"),
      dateInput("date", "dateInput", Sys.Date(), width = "100%"),
      dateRangeInput(
        "date_range",
        "dateRangeInput",
        start = Sys.Date() - 7,
        end = Sys.Date(),
        width = "100%"
      )
    ),
    card(
      card_header("File upload"),
      fileInput("file", "fileInput", accept = c(".txt", ".csv", ".pdf"), width = "100%")
    ),
    card(
      card_header("Buttons & links"),
      div(
        class = "d-flex flex-wrap gap-2 align-items-center",
        actionButton("action", "actionButton", class = "btn-primary"),
        actionLink("action_link", "actionLink")
      ),
      div(
        class = "d-flex flex-wrap gap-2 align-items-center mt-2",
        # Client-side BS5 modal open (works even if Shiny custom messages lag)
        tags$button(
          type = "button",
          class = "btn btn-outline-primary",
          id = "show_modal",
          `data-bs-toggle` = "modal",
          `data-bs-target` = "#glass_demo_modal",
          "Show modal"
        ),
        downloadButton("download", "downloadButton"),
        downloadLink("download_link", "downloadLink")
      ),
      tags$form(
        class = "mt-2",
        textInput("submit_text", NULL, "Form field", width = "100%"),
        submitButton("submitButton")
      )
    ),
    card(
      card_header("Live values"),
      class = "bslib-card",
      # renderPrint + verbatimTextOutput is the reliable pair for str()-style dumps
      verbatimTextOutput("values", placeholder = TRUE)
    )
  ),
  # Static Bootstrap 5 modal (client open) so it works even if custom messages
  # are flaky; glass_theme styles .modal-content + .modal-backdrop blur.
  tags$div(
    class = "modal fade",
    id = "glass_demo_modal",
    tabindex = "-1",
    `aria-labelledby` = "glass_demo_modal_title",
    `aria-hidden` = "true",
    tags$div(
      class = "modal-dialog modal-dialog-centered",
      tags$div(
        class = "modal-content",
        tags$div(
          class = "modal-header",
          tags$h5(
            class = "modal-title",
            id = "glass_demo_modal_title",
            "Glass modal"
          ),
          tags$button(
            type = "button",
            class = "btn-close",
            `data-bs-dismiss` = "modal",
            `aria-label` = "Close"
          )
        ),
        tags$div(
          class = "modal-body",
          p(
            "This dialog is a Bootstrap modal under ",
            code("glass_theme()"),
            ". The page behind frosts with backdrop blur (same idea as the file-picker scrim)."
          ),
          selectInput(
            "modal_choice",
            "Modal selectInput",
            c("Ultra Clear", "Balanced", "Tinted"),
            selected = "Balanced",
            width = "100%"
          ),
          textInput(
            "modal_text",
            "Modal textInput",
            "Hello from the modal",
            width = "100%"
          )
        ),
        tags$div(
          class = "modal-footer",
          tags$button(
            type = "button",
            class = "btn btn-secondary",
            `data-bs-dismiss` = "modal",
            "Close"
          ),
          # data-bs-dismiss closes on the client; server still gets the click
          actionButton(
            "modal_ok",
            "OK",
            class = "btn-primary",
            `data-bs-dismiss` = "modal"
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Client applies preset live; this keeps the server session aligned
  observe_glass_preset_input(input, session, "preset")

  observeEvent(input$action, {
    showNotification("actionButton clicked", type = "message", duration = 3)
  })

  observeEvent(input$action_link, {
    showNotification("actionLink clicked", type = "message", duration = 3)
  })

  # Client data-bs-toggle / data-bs-dismiss open and close the modal.
  observeEvent(input$modal_ok, {
    showNotification(
      paste0(
        "Modal OK - ",
        input$modal_choice %||% "?",
        " / ",
        input$modal_text %||% ""
      ),
      type = "message",
      duration = 3
    )
  })

  output$download <- downloadHandler(
    filename = function() {
      paste0("shinyglass-inputs-", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      write.csv(mtcars, file, row.names = FALSE)
    }
  )

  output$download_link <- downloadHandler(
    filename = function() {
      paste0("shinyglass-inputs-", format(Sys.Date(), "%Y%m%d"), ".txt")
    },
    content = function(file) {
      writeLines(c("shinyglass inputs gallery", capture.output(str(reactiveValuesToList(input)))), file)
    }
  )

  output$values <- renderPrint({
    file_label <- if (is.null(input$file)) {
      NULL
    } else {
      list(
        name = input$file$name,
        size = input$file$size,
        type = input$file$type
      )
    }

    # Avoid str() inside renderText (returns NULL). renderPrint captures it.
    list(
      textInput = input$text,
      passwordInput = if (isTruthy(input$password) && nzchar(input$password)) "<redacted>" else "",
      textAreaInput = input$textarea,
      numericInput = input$numeric,
      sliderInput = input$slider,
      sliderInput_range = input$slider_range,
      selectInput = input$select,
      selectizeInput = input$selectize,
      selectizeInput_single = input$selectize_single,
      checkboxInput = input$checkbox,
      checkboxGroupInput = input$checkbox_group,
      radioButtons = input$radio,
      varSelectInput = as.character(input$var_select),
      varSelectizeInput = as.character(input$var_selectize),
      dateInput = as.character(input$date),
      dateRangeInput = as.character(input$date_range),
      fileInput = file_label,
      submitButton = input$submit_text,
      theme_preset = input$preset,
      modal_choice = input$modal_choice,
      modal_text = input$modal_text
    )
  })
}

shinyApp(ui, server)
