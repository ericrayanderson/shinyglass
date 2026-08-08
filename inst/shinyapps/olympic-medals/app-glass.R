library(shiny)
library(shinyWidgets)
library(ggplot2)
library(ggthemes)
library(bslib)
library(dplyr)
library(data.table)
library(reactable)
library(tidyr)
library(ggtext)
library(shinyglass)

source("R/data.R")
source("R/visualisation.R")

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "auto"),
  c("light", "dark", "auto")
)
medals_summer <- readRDS(file = "datas/medals_summer.rds")

ui <- fluidPage(
  title = "R-Olympics",
  theme = glass_theme(preset = glass_preset),
  tags$head(
    tags$link(
      rel = "icon", type = "image/png", sizes = "32x32",
      href = "rings.png"
    ),
    tags$style(HTML("
      .olympics-hero img {
        max-width: min(200px, 55vw);
        height: auto;
      }
      .olympics-wrap {
        max-width: 960px;
        margin-left: auto;
        margin-right: auto;
      }
      @media (max-width: 575.98px) {
        .olympics-filters .col-filter { margin-bottom: 0.75rem; }
        .olympics-settings-btn { width: 100% !important; }
      }
    "))
  ),
  # Full width on phones; centered readable column on larger screens
  div(
    class = "container-fluid px-2 px-sm-3 mt-3 mb-4 olympics-wrap",
    card(
      tags$div(
        class = "text-center olympics-hero",
        tags$img(
          src = "rings.jpg",
          alt = "Olympic rings",
          width = 200,
          height = 100
        ),
        tags$h2("An overview of olympic medals", class = "h3 mt-2")
      ),
      fluidRow(
        class = "olympics-filters g-2 align-items-end",
        column(
          width = 12,
          class = "col-md-5 col-filter",
          virtualSelectInput(
            inputId = "discipline",
            label = "Select discipline:",
            choices = unique(medals_summer$discipline_title),
            multiple = TRUE,
            selected = NULL,
            width = "100%"
          )
        ),
        column(
          width = 12,
          class = "col-md-5 col-filter",
          virtualSelectInput(
            inputId = "summer_og",
            label = "Select game edition:",
            choices = unique(medals_summer$slug_game),
            multiple = TRUE,
            selected = NULL,
            width = "100%"
          )
        ),
        column(
          width = 12,
          class = "col-md-2 col-filter",
          tags$div(
            class = "shiny-input-container",
            tags$label(class = "control-label d-none d-md-block", "Settings"),
            dropMenu(
              actionButton(
                inputId = "btn",
                label = "Settings",
                class = "btn-outline-primary olympics-settings-btn",
                icon = icon("medal"),
                width = "100%"
              ),
              checkboxGroupButtons(
                inputId = "medal_type",
                label = "Select medal type:",
                choiceValues = unique(medals_summer$medal_type),
                direction = "vertical",
                choiceNames = list(
                  tags$span(icon("medal"), "GOLD", style = "color: #9F8F5E;"),
                  tags$span(icon("medal"), "SILVER", style = "color: #969696"),
                  tags$span(icon("medal"), "BRONZE", style = "color: #996B4F")
                ),
                selected = unique(medals_summer$medal_type),
                width = "100%",
                status = "outline-primary"
              ),
              numericInput(
                inputId = "top",
                label = "Number of countries displayed:",
                value = 10,
                min = 1,
                max = length(unique(medals_summer$country_name)),
                width = "100%"
              ),
              placement = "bottom-start",
              theme = "light",
              padding = "0px"
            )
          )
        )
      ),
      plotOutput(outputId = "graph", height = "auto", width = "100%"),
      tags$br(),
      div(class = "table-responsive", reactableOutput("table")),
      tags$br(),
      card(
        card_header("Data: Source & Download"),
        card_body(
          tags$div(
            icon("save"),
            downloadLink(
              outputId = "downloadData",
              label = "Download Data"
            )
          ),
          tags$a(
            icon("link"),
            "Olympic games medals dataset (Kaggle)",
            href = "https://www.kaggle.com/datasets/piterfm/olympic-games-medals-19862018",
            target = "_blank",
            rel = "noopener noreferrer"
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  data_in_pre <- reactive({
    filter_discipline(
      data = medals_summer,
      discipline_v = input$discipline
    ) %>%
      filter_slug_game(slug_game_v = input$summer_og) %>%
      filter_medal_type(medal_type_v = input$medal_type) %>%
      medal_calc()
  })
  data_in <- reactive({
    data_in_pre() %>%
      filter_top(top_n = input$top)
  })
  data_in_pivot <- reactive({
    data_in_pre() %>%
      pivot_wider(names_from = medal_type, values_from = n_medal) %>%
      select(1:2, any_of(c("GOLD", "SILVER", "BRONZE")))
  })
  output$table <- renderReactable({
    table_medal(data_in_pivot())
  })
  hght <- reactive({
    # Cap height so the chart stays scannable on phones
    n <- input$top
    if (is.null(n) || length(n) == 0 || is.na(n)) n <- 10
    base <- 50 + 30 * max(1L, as.integer(n))
    min(base, 900)
  })
  output$graph <- renderPlot(
    {
      visualisation_medal(x = data_in())
    },
    height = hght,
    res = 96
  )
  output$downloadData <- downloadHandler(
    filename = function() {
      "data-olympic.csv"
    },
    content = function(file) {
      write.csv(data_in(), file)
    }
  )
}

shinyApp(ui = ui, server = server)
