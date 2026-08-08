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
    selectInput(
      "preset",
      "Theme preset",
      choices = c("Light" = "light", "Dark" = "dark", "Auto (OS)" = "auto"),
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
      tags$form(
        textInput("submit_text", NULL, "Form field", width = "100%"),
        submitButton("submitButton")
      ),
      div(
        class = "d-flex flex-wrap gap-2 align-items-center mt-2",
        downloadButton("download", "downloadButton"),
        downloadLink("download_link", "downloadLink")
      )
    ),
    card(
      card_header("Live values"),
      class = "bslib-card",
      verbatimTextOutput("values")
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$preset, {
    update_glass_theme(session, preset = input$preset)
  }, ignoreInit = TRUE)

  observeEvent(input$action, {
    showNotification("actionButton clicked", type = "message", duration = 3)
  })

  observeEvent(input$action_link, {
    showNotification("actionLink clicked", type = "message", duration = 3)
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

  output$values <- renderText({
    file_label <- if (is.null(input$file)) {
      NULL
    } else {
      list(
        name = input$file$name,
        size = input$file$size,
        type = input$file$type
      )
    }

    str(list(
      textInput = input$text,
      passwordInput = if (nzchar(input$password)) "<redacted>" else "",
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
      varSelectInput = input$var_select,
      varSelectizeInput = input$var_selectize,
      dateInput = as.character(input$date),
      dateRangeInput = as.character(input$date_range),
      fileInput = file_label,
      submitButton = input$submit_text
    ))
  })
}

shinyApp(ui, server)
