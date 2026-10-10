# Liquid Glass chat. No API key: replies are a local echo.
#   shiny::runApp(system.file("examples/shinychat-glass", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)
library(shinychat)

`%||%` <- function(x, y) if (is.null(x)) y else x

# History reads provider@name. Register once so re-sourcing the example
# does not rebuild the class.
if (!methods::isClass("GlassEchoProvider")) {
  suppressWarnings(methods::setClass(
    "GlassEchoProvider",
    slots = c(name = "character", model = "character")
  ))
}

echo_piece <- function(part) {
  if (is.character(part)) return(paste(part, collapse = " "))
  if (inherits(part, "S7_object")) {
    props <- tryCatch(S7::props(part), error = function(e) list())
    if (!is.null(props$text)) return(as.character(props$text))
  }
  if (is.list(part) && !is.null(part$text)) return(as.character(part$text))
  ""
}

make_echo_chat <- function() {
  stored_turns <- list()
  prompt <- ""
  tools <- list()
  client <- list(
    get_turns = function() stored_turns,
    set_turns = function(value) {
      stored_turns <<- value
      invisible(client)
    },
    get_tools = function() tools,
    set_tools = function(value) {
      tools <<- value
      invisible(client)
    },
    get_system_prompt = function() prompt,
    set_system_prompt = function(value) {
      prompt <<- value %||% ""
      invisible(client)
    },
    get_model = function() "local-echo",
    get_provider = function() {
      methods::new(
        "GlassEchoProvider",
        name = "Local echo",
        model = "local-echo"
      )
    },
    clone = function() make_echo_chat()
  )
  class(client) <- c("Chat", "R6")
  client
}

echo_reply <- function(text) {
  paste0(
    "<thinking>\nEchoing on this machine. No model key.\n</thinking>\n\n",
    "Echo: ", text, " ",
    "<shiny-aside label=\"Field log\" url=\"https://example.com\">Dawn reading.</shiny-aside>."
  )
}

tide_block <- function() {
  structure(
    list(
      type = "tool_result",
      version = 1L,
      request_id = "tide-1",
      tool_name = "tide_table",
      status = "success",
      title = "Read the tide table",
      label = "Harbor",
      value_preview = "1.4 m",
      value = "High tide 1.4 m at 06:10.",
      show_request = FALSE,
      expanded = TRUE,
      open_style = "framed"
    ),
    class = c("shinychat_tool_result", "shinychat_tool_card", "shinychat_block")
  )
}

ui <- page_chat(
  "Glass notes",
  id = "chat",
  theme = glass_theme(),
  allow_attachments = FALSE,
  placeholder = "Message",
  greeting = paste(
    "## Glass notes",
    "Local echo. No model key.",
    "* <span class=\"suggestion\">Capture a harbor note</span>",
    sep = "\n"
  ),
  footer = tags$p("Echo stays on this machine."),
  sidebar = chat_sidebar(
    tags$h3("Workspace", class = "h6"),
    textInput("project", "Project", "Harbor"),
    history = TRUE,
    width = 280,
    open = "always"
  ),
  toolbar = toolbar(
    toolbar_input_button("show_sample", "Sample"),
    toolbar_input_button("open_sources", "Sources")
  ),
  pages_navbar = list(
    chat_nav_panel(
      "Preview",
      tags$h2("Artifact preview"),
      tags$div(
        class = "shiny-chat-text-preview",
        id = "artifact_preview",
        tags$div(class = "shiny-chat-text-preview-name", "notes.txt"),
        tags$div(class = "shiny-chat-text-preview-body", "Dawn reading, 1.4 m.")
      ),
      tags$div(
        class = "shiny-chat-attachment-badge",
        id = "artifact_chip",
        "notes.txt"
      ),
      sidebar = FALSE
    ),
    chat_nav_panel(
      "Embed",
      chat_ui(
        "embed",
        height = "440px",
        show_history = FALSE,
        allow_attachments = FALSE,
        greeting = "Embedded chat_ui on glass.",
        placeholder = "Note"
      ),
      sidebar = FALSE
    )
  )
)

server <- function(input, output, session) {
  client <- make_echo_chat()
  # chat_append keeps the demo off the network. chat_server() is the
  # production path once you have an ellmer client with stream_async().
  chat_enable_history(
    "chat",
    client,
    options = history_options(store = "memory", title = NULL)
  )
  session$onFlushed(function() {
    shinychat:::send_chat_action(
      "chat",
      list(
        type = "update_slash_commands",
        commands = list(list(
          name = "note",
          description = "Save a local note",
          echo = FALSE
        ))
      ),
      session = session
    )
  }, once = TRUE)

  observeEvent(input$chat_user_input, {
    text <- input$chat_user_input
    if (!is.character(text)) {
      text <- paste(vapply(text, echo_piece, character(1)), collapse = " ")
    }
    chat_append("chat", echo_reply(text))
  }, ignoreInit = TRUE)

  observeEvent(input$chat_slash_command, {
    chat_append("chat", "Saved the note locally.")
  }, ignoreInit = TRUE)

  observeEvent(input$show_sample, {
    chat_append_message(
      "chat",
      list(
        role = "assistant",
        content = list(
          paste0(
            "<thinking>\nChecking the harbor log.\n</thinking>\n\n",
            "The harbor is calm ",
            "<shiny-aside label=\"Field log\" url=\"https://example.com\">Dawn reading.</shiny-aside>."
          ),
          tide_block()
        )
      ),
      chunk = FALSE
    )
  }, ignoreInit = TRUE)

  observeEvent(input$open_sources, {
    show_offcanvas(
      offcanvas(
        id = "sources_panel",
        title = "Sources",
        placement = "end",
        p("Citations stay in this glass panel."),
        div(
          id = "oc_spacer",
          style = "min-height: 140vh;",
          "Scroll the panel to see the header edge."
        )
      ),
      session = session
    )
  }, ignoreInit = TRUE)

  observeEvent(input$embed_user_input, {
    text <- input$embed_user_input
    if (is.list(text)) text <- paste(vapply(text, echo_piece, character(1)), collapse = " ")
    chat_append("embed", paste("Embed echo:", text))
  }, ignoreInit = TRUE)
}

app <- shinyApp(ui, server)
app
