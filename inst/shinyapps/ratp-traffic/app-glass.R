library(shiny)
library(shinyglass)

glass_preset <- match.arg(Sys.getenv("SHINYGLASS_PRESET", "light"), c("light", "dark"))

source("global.R")
server <- eval(parse("server.R")[[1L]])

ui_call <- parse("ui.R")[[2L]]
ui_call$theme <- substitute(
  glass_theme(preset = glass_preset),
  list(glass_preset = glass_preset)
)
ui <- eval(ui_call, envir = environment())

shinyApp(ui, server)