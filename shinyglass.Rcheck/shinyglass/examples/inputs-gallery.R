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
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark")
)

ui <- page_sidebar(
  title = "Shiny Inputs Gallery",
  theme = glass_theme(preset = glass_preset),
  fillable = TRUE,
  sidebar = sidebar(
    title = "About",
    width = 300,
    p(
      class = "text-muted",
      "Every built-in Shiny input and button, styled with ",
      code("glass_theme()"), ". Change controls on the right — values update live below."
    ),
    selectInput(
      "preset",
      "Theme preset",
      choices = c("Light" = "light", "Dark" = "dark"),
      selected = glass_preset
    ),
    tags$hr(),
    tags$small(
      class = "text-muted",
      "Set SHINYGLASS_PRESET=dark before launch to start in dark mode."
    )
  ),
  layout_column_wrap(
    width = 1 / 2,
    heights_equal = "row",
    card(
      card_header("Text & numbers"),
      textInput("text", "textInput", "Hello glass"),
      passwordInput("password", "passwordInput", "secret"),
      textAreaInput("textarea", "textAreaInput", "Multi-line\ntext", rows = 3),
      numericInput("numeric", "numericInput", 42, min = 0, max = 100)
    ),
    card(
      card_header("Slider"),
      sliderInput("slider", "sliderInput", 0, 100, 50, step = 5),
      sliderInput(
        "slider_range",
        "sliderInput (range)",
        min = 0,
        max = 100,
        value = c(25, 75)
      )
    ),
    card(
      card_header("Select menus"),
      selectInput(
        "select",
        "selectInput",
        c("Apple" = "apple", "Banana" = "banana", "Cherry" = "cherry"),
        selected = "banana"
      ),
      selectizeInput(
        "selectize",
        "selectizeInput",
        c("Red" = "red", "Green" = "green", "Blue" = "blue"),
        selected = "blue",
        multiple = TRUE
      ),
      selectizeInput(
        "selectize_single",
        "selectizeInput (single)",
        state.name,
        selected = "California"
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
        inline = TRUE
      ),
      radioButtons(
        "radio",
        "radioButtons",
        c("Small" = "sm", "Medium" = "md", "Large" = "lg"),
        selected = "md",
        inline = TRUE
      )
    ),
    card(
      card_header("Variable selectors"),
      varSelectInput("var_select", "varSelectInput", mtcars, selected = "mpg"),
      varSelectizeInput(
        "var_selectize",
        "varSelectizeInput",
        iris,
        selected = "Species",
        multiple = TRUE
      )
    ),
    card(
      card_header("Dates"),
      dateInput("date", "dateInput", Sys.Date()),
      dateRangeInput(
        "date_range",
        "dateRangeInput",
        start = Sys.Date() - 7,
        end = Sys.Date()
      )
    ),
    card(
      card_header("File upload"),
      fileInput("file", "fileInput", accept = c(".txt", ".csv", ".pdf"))
    ),
    card(
      card_header("Buttons & links"),
      actionButton("action", "actionButton", class = "btn-primary"),
      actionLink("action_link", "actionLink"),
      tags$form(
        textInput("submit_text", NULL, "Form field", width = "100%"),
        submitButton("submitButton")
      ),
      downloadButton("download", "downloadButton"),
      downloadLink("download_link", "downloadLink")
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
    session$sendCustomMessage("glassPreset", input$preset)
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