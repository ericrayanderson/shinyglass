# Broad compatibility fixture for Liquid Glass defaults.
#
# Covers inputs, tables, charts, maps, overlays, modules, dynamic UI, and a
# tall card stack. Optional packages degrade to a marker the browser tests
# can skip. Run:
#   shiny::runApp(system.file("examples", "compat-glass.R", package = "shinyglass"))
# Playwright launches inst/scripts/browser/compat-app.R.

library(shiny)
library(bslib)
library(shinyglass)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (is.character(x) && !nzchar(x[[1]]))) y else x
}

has_pkg <- function(pkg) isTRUE(requireNamespace(pkg, quietly = TRUE))

compat_pkgs <- c(
  "DT", "ggplot2", "plotly", "leaflet", "reactable", "shinyWidgets",
  "shinyjs", "waiter", "shinycssloaders", "echarts4r"
)
compat_present <- stats::setNames(vapply(compat_pkgs, has_pkg, logical(1)), compat_pkgs)

missing_note <- function(pkg) {
  div(
    class = "compat-missing text-muted",
    `data-missing` = pkg,
    paste(pkg, "is not installed")
  )
}

answer_ui <- function(id) {
  ns <- NS(id)
  tagList(
    textInput(ns("ans"), "Module answer", "glass"),
    textOutput(ns("echo"))
  )
}

answer_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$echo <- renderText(paste("module:", input$ans))
  })
}

ui <- function(request) {
  qs <- parseQueryString(request$QUERY_STRING %||% "")
  preset <- match.arg(qs$preset %||% "light", c("light", "dark", "auto"))
  on <- function(name) !identical(qs[[name]], "0")
  icon_style <- qs$icon_style %||% "clear"
  if (!icon_style %in% c("clear", "color", "all")) icon_style <- "clear"

  theme <- glass_theme(
    preset = preset,
    refraction = on("refraction"),
    morph = on("morph"),
    press = on("press"),
    scroll_edge = on("scroll_edge"),
    minimize_tabs = on("minimize_tabs"),
    icon_style = icon_style
  )

  plot_ui <- plotOutput("plot", height = "220px")
  if (isTRUE(compat_present[["shinycssloaders"]])) {
    plot_ui <- shinycssloaders::withSpinner(plot_ui, type = 4, color = "#007AFF")
  }

  tagList(
    if (isTRUE(compat_present[["shinyjs"]])) shinyjs::useShinyjs(),
    if (isTRUE(compat_present[["waiter"]])) waiter::useWaiter(),
    div(
      id = "compat_packages",
      style = "display:none",
      `data-pkgs` = paste(names(compat_present)[compat_present], collapse = ",")
    ),
    navbarPage(
      title = tagList(icon("droplet"), "Glass compat"),
      id = "main_nav",
      theme = theme,
      collapsible = TRUE,
      windowTitle = "Glass compat",
      tabPanel(
        "Inputs",
        div(
          class = "d-flex flex-wrap gap-2 align-items-center mb-3",
          input_dark_mode(id = "color_mode", mode = if (preset == "dark") "dark" else "light"),
          actionButton("ping", tagList(icon("sliders"), "Ping"), class = "btn-secondary"),
          textOutput("ping_out", inline = TRUE),
          textOutput("mode_out", inline = TRUE)
        ),
        layout_columns(
          card(
            card_header("Selects"),
            selectInput("sel", "selectInput", c("Alpha", "Beta", "Gamma"), selected = "Alpha"),
            selectInput(
              "sel_native", "selectInput native", c("One", "Two", "Three"),
              selected = "One", selectize = FALSE
            ),
            if (isTRUE(compat_present[["shinyWidgets"]])) {
              tagList(
                shinyWidgets::pickerInput(
                  "picker", "pickerInput",
                  choices = c("Red", "Blue", "Green"),
                  selected = "Red", width = "100%"
                ),
                shinyWidgets::materialSwitch("sw", "Switch", value = TRUE, status = "primary"),
                shinyWidgets::sliderTextInput(
                  "sw_slider", "sliderTextInput",
                  choices = c("S", "M", "L"), selected = "M", width = "100%"
                )
              )
            } else {
              missing_note("shinyWidgets")
            },
            textOutput("sel_out")
          ),
          card(
            card_header("Dates and files"),
            dateInput("date", "dateInput", value = as.Date("2026-06-15")),
            dateRangeInput(
              "date_range", "dateRangeInput",
              start = as.Date("2026-06-01"), end = as.Date("2026-06-15")
            ),
            fileInput("file", "fileInput", accept = c(".csv", ".txt")),
            textOutput("file_out"),
            sliderInput("n", "sliderInput", 1, 10, 4),
            checkboxInput("show_extra", "Show extra", FALSE),
            conditionalPanel(
              "input.show_extra == true",
              p(id = "extra_panel", "Extra panel is visible")
            )
          ),
          col_widths = c(6, 6)
        ),
        div(id = "page_spacer", style = "height: 80vh")
      ),
      tabPanel(
        "Data",
        layout_columns(
          card(card_header("ggplot2 / renderPlot"), plot_ui),
          card(
            card_header("plotly"),
            if (isTRUE(compat_present[["plotly"]])) {
              plotly::plotlyOutput("ply", height = "240px")
            } else {
              missing_note("plotly")
            }
          ),
          card(
            card_header("leaflet"),
            if (isTRUE(compat_present[["leaflet"]])) {
              leaflet::leafletOutput("map", height = "240px")
            } else {
              missing_note("leaflet")
            }
          ),
          card(
            card_header("echarts4r"),
            if (isTRUE(compat_present[["echarts4r"]])) {
              echarts4r::echarts4rOutput("ec", height = "240px")
            } else {
              missing_note("echarts4r")
            }
          ),
          card(
            card_header("DT"),
            if (isTRUE(compat_present[["DT"]])) {
              DT::DTOutput("dt")
            } else {
              missing_note("DT")
            }
          ),
          card(
            card_header("reactable"),
            if (isTRUE(compat_present[["reactable"]])) {
              reactable::reactableOutput("rt")
            } else {
              missing_note("reactable")
            }
          ),
          col_widths = c(6, 6, 6, 6, 12, 12)
        )
      ),
      tabPanel(
        "Overlays",
        layout_columns(
          card(
            card_header("Modal and notification"),
            actionButton("open_modal", "showModal"),
            actionButton("notify", "Notify", class = "btn-primary"),
            downloadButton("dl", "Download"),
            textOutput("modal_out")
          ),
          card(
            card_header("Tooltip and popover"),
            tooltip(
              actionButton("tip_btn", "Hover tooltip", class = "btn-outline-primary"),
              "Tooltip on glass"
            ),
            popover(
              actionButton("pop_btn", "Open popover", class = "btn-outline-primary"),
              title = "Popover",
              "Popover body on glass."
            )
          ),
          card(
            card_header("shinyjs and waiter"),
            if (isTRUE(compat_present[["shinyjs"]])) {
              tagList(
                div(id = "js_note", "shinyjs note"),
                actionButton("js_hide", "Hide note"),
                actionButton("js_show", "Show note")
              )
            } else {
              missing_note("shinyjs")
            },
            if (isTRUE(compat_present[["waiter"]])) {
              actionButton("spin", "Show waiter")
            } else {
              missing_note("waiter")
            }
          ),
          col_widths = c(4, 4, 4)
        )
      ),
      tabPanel(
        "Layout",
        layout_columns(
          value_box(
            title = "Visitors",
            value = textOutput("visitors", inline = TRUE),
            showcase = icon("user")
          ),
          card(
            card_header("Accordion"),
            accordion(
              id = "acc",
              open = "One",
              accordion_panel("One", p(id = "acc_one", "First panel")),
              accordion_panel("Two", p(id = "acc_two", "Second panel"))
            )
          ),
          card(
            card_header("Navset and tabset"),
            navset_pill(
              id = "pills",
              nav_panel("Pill A", p(id = "pill_a", "Pill A body")),
              nav_panel("Pill B", p(id = "pill_b", "Pill B body"))
            ),
            tabsetPanel(
              id = "classic_tabs",
              tabPanel("Alpha", p(id = "tab_alpha", "Alpha panel")),
              tabPanel("Beta", p(id = "tab_beta", "Beta panel"))
            )
          ),
          col_widths = c(4, 4, 4)
        ),
        layout_sidebar(
          sidebar = sidebar(
            id = "side",
            textInput("side_q", "Filter", "glass")
          ),
          card(
            card_header("Sidebar main"),
            textOutput("side_echo"),
            actionButton("add_dyn", "renderUI"),
            uiOutput("dyn"),
            actionButton("do_insert", "insertUI"),
            div(id = "insert_host"),
            answer_ui("mod")
          )
        )
      ),
      tabPanel(
        "Scroll",
        p(id = "scroll_intro", "Many cards under the floating bar."),
        div(
          id = "scroll_deck",
          style = "height: 70vh; overflow: auto; padding-right: 0.25rem;",
          lapply(seq_len(36), function(i) {
            card(
              id = paste0("deck_", i),
              card_header(paste("Card", i)),
              p(paste("Row", i, "stays readable on glass."))
            )
          })
        )
      )
    )
  )
}

server <- function(input, output, session) {
  answer_server("mod")
  ping_n <- reactiveVal(0L)
  modal_val <- reactiveVal("")

  output$ping_out <- renderText(paste("pings", ping_n()))
  output$mode_out <- renderText(paste("mode", input$color_mode %||% "light"))
  output$visitors <- renderText("128")
  output$sel_out <- renderText({
    paste(
      input$sel %||% "",
      input$sel_native %||% "",
      input$picker %||% "",
      if (isTRUE(input$sw)) "on" else "off",
      input$sw_slider %||% ""
    )
  })
  output$file_out <- renderText({
    if (is.null(input$file)) "no file" else input$file$name
  })
  output$side_echo <- renderText(paste("filter", input$side_q %||% ""))
  output$modal_out <- renderText(modal_val())

  output$plot <- renderPlot({
    x <- seq_len(8)
    y <- x + (input$n %||% 4)
    if (isTRUE(compat_present[["ggplot2"]])) {
      df <- data.frame(x = x, y = y)
      print(
        ggplot2::ggplot(df, ggplot2::aes(x, y)) +
          ggplot2::geom_col(fill = "#007AFF") +
          ggplot2::theme_minimal()
      )
    } else {
      barplot(y, col = "#007AFF", border = NA)
    }
  }, bg = "transparent")

  if (isTRUE(compat_present[["plotly"]])) {
    output$ply <- plotly::renderPlotly({
      plotly::layout(
        plotly::plot_ly(
          x = seq_len(5),
          y = c(2, 4, 3, 5, 1),
          type = "scatter",
          mode = "lines+markers",
          hoverinfo = "text",
          text = paste("Point", seq_len(5))
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)"
      )
    })
  }

  if (isTRUE(compat_present[["leaflet"]])) {
    output$map <- leaflet::renderLeaflet({
      leaflet::setView(
        leaflet::addCircleMarkers(
          leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = TRUE)),
          lng = -0.12, lat = 51.5, radius = 14,
          popup = "Glass popup", layerId = "pin",
          color = "#007AFF", fillOpacity = 0.9
        ),
        -0.12, 51.5, zoom = 4
      )
    })
  }

  if (isTRUE(compat_present[["echarts4r"]])) {
    output$ec <- echarts4r::renderEcharts4r({
      df <- data.frame(x = letters[1:5], y = c(3, 5, 2, 8, 4))
      echarts4r::e_line(echarts4r::e_charts(df, x), y)
    })
  }

  if (isTRUE(compat_present[["DT"]])) {
    output$dt <- DT::renderDT({
      DT::datatable(
        iris[1:12, ],
        options = list(pageLength = 5, dom = "tp"),
        rownames = FALSE,
        selection = "none"
      )
    })
  }

  if (isTRUE(compat_present[["reactable"]])) {
    output$rt <- reactable::renderReactable({
      reactable::reactable(iris[1:8, ], defaultPageSize = 4)
    })
  }

  observeEvent(input$ping, ping_n(ping_n() + 1L), ignoreInit = TRUE)

  output$dyn <- renderUI({
    n <- input$add_dyn
    if (is.null(n) || n < 1) return(NULL)
    textInput("dyn_text", "Dynamic", paste("n", n))
  })

  observeEvent(input$do_insert, {
    insertUI(
      "#insert_host",
      ui = textInput(paste0("ins", input$do_insert), "Inserted", "ok")
    )
  }, ignoreInit = TRUE)

  observeEvent(input$open_modal, {
    showModal(modalDialog(
      title = "Compat modal",
      easyClose = TRUE,
      footer = tagList(
        modalButton("Close"),
        actionButton("modal_ok", "OK", class = "btn-primary")
      ),
      textInput("modal_name", "Name", "Ada")
    ))
  }, ignoreInit = TRUE)

  observeEvent(input$modal_ok, {
    modal_val(input$modal_name %||% "")
    removeModal()
  }, ignoreInit = TRUE)

  observeEvent(input$notify, {
    showNotification("Saved from glass", type = "message", duration = 6)
  }, ignoreInit = TRUE)

  output$dl <- downloadHandler(
    filename = function() "glass-compat.csv",
    content = function(file) {
      write.csv(data.frame(a = 1, b = "glass"), file, row.names = FALSE)
    }
  )

  if (isTRUE(compat_present[["shinyjs"]])) {
    observeEvent(input$js_hide, shinyjs::hide("js_note"), ignoreInit = TRUE)
    observeEvent(input$js_show, shinyjs::show("js_note"), ignoreInit = TRUE)
  }

  if (isTRUE(compat_present[["waiter"]])) {
    observeEvent(input$spin, {
      waiter::waiter_show(
        html = tags$span(id = "waiter_label", "Loading"),
        color = "rgba(20, 20, 24, 0.35)"
      )
      # waiter_hide() uses getDefaultReactiveDomain(). A later() callback
      # has no domain, so that call is a NULL session and stops the app.
      later::later(function() {
        session$sendCustomMessage("waiter-hide", list(id = NULL))
      }, 0.4)
    }, ignoreInit = TRUE)
  }
}

app <- shinyApp(ui, server)
app
