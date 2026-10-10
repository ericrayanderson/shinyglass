# Harbor notes: the shinyglass chat demo.
# Local script by default. Set OPENAI_API_KEY for a live ellmer client.
#   shiny::runApp(system.file("examples/shinychat-glass", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)
library(shinychat)

`%||%` <- function(x, y) if (is.null(x)) y else x

# History reads provider@name. Register once so re-sourcing does not rebuild it.
if (!methods::isClass("GlassEchoProvider")) {
  suppressWarnings(methods::setClass(
    "GlassEchoProvider",
    slots = c(name = "character", model = "character")
  ))
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
    get_model = function() "local-script",
    get_provider = function() {
      methods::new(
        "GlassEchoProvider",
        name = "Local script",
        model = "local-script"
      )
    },
    clone = function() make_echo_chat()
  )
  class(client) <- c("Chat", "R6")
  client
}

# Group words so the reply types itself, without splitting the citation tag.
harbor_pieces <- function(text) {
  text <- gsub("[[:space:]]+", " ", trimws(text %||% ""))
  if (!nzchar(text)) text <- "the morning harbor"
  if (nchar(text) > 90) text <- paste0(substr(text, 1, 87), "...")
  body <- paste0(
    "Dawn at the harbor is quiet. You asked: ", text, ". ",
    "High tide is 1.4 m at 06:10, and the water is already turning."
  )
  words <- strsplit(body, " ", fixed = TRUE)[[1]]
  chunks <- character()
  buf <- character()
  for (w in words) {
    buf <- c(buf, w)
    if (length(buf) >= 3L) {
      chunks <- c(chunks, paste0(paste(buf, collapse = " "), " "))
      buf <- character()
    }
  }
  if (length(buf)) chunks <- c(chunks, paste0(paste(buf, collapse = " "), " "))
  c(
    list("<thinking>\nChecking the harbor log for dawn.\n</thinking>\n\n"),
    as.list(chunks),
    list("<shiny-aside label=\"Field log\" url=\"https://example.com\">Dawn reading.</shiny-aside>"),
    list(tide_block())
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

stream_pieces <- function(id, pieces, session, pace) {
  n <- length(pieces)
  i <- 0L
  step <- function() {
    i <<- i + 1L
    if (i > n) return(invisible(NULL))
    chunk <- if (n == 1L) {
      FALSE
    } else if (i == 1L) {
      "start"
    } else if (i == n) {
      "end"
    } else {
      TRUE
    }
    chat_append_message(
      id,
      list(role = "assistant", content = pieces[[i]]),
      chunk = chunk,
      session = session
    )
    if (i < n) {
      if (pace > 0) later::later(step, pace) else step()
    }
    invisible(NULL)
  }
  step()
}

user_text <- function(value) {
  if (is.character(value)) return(paste(value, collapse = " "))
  if (is.list(value) && !is.null(value$text)) return(as.character(value$text))
  paste(as.character(value), collapse = " ")
}

live_requested <- function() nzchar(Sys.getenv("OPENAI_API_KEY"))

make_client <- function() {
  if (!live_requested()) {
    return(list(client = make_echo_chat(), live = FALSE))
  }
  model <- Sys.getenv("SHINYGLASS_CHAT_MODEL", "gpt-4o-mini")
  client <- tryCatch(
    ellmer::chat_openai(
      system_prompt = paste(
        "You are a calm harbor guide inside a Liquid Glass demo.",
        "Answer in two or three short sentences."
      ),
      model = model
    ),
    error = function(e) NULL
  )
  if (is.null(client)) {
    warning("OPENAI_API_KEY is set, but the live client did not start. Using the local script.", call. = FALSE)
    return(list(client = make_echo_chat(), live = FALSE))
  }
  list(client = client, live = TRUE)
}

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark", "auto")
)

ui <- page_chat(
  "Harbor notes",
  id = "chat",
  theme = glass_theme(
    preset = glass_preset,
    scene = "dusk",
    intensity = 0.38,
    primary = "#007AFF"
  ),
  allow_attachments = FALSE,
  placeholder = "Message",
  greeting = paste(
    "## Harbor notes",
    "Liquid Glass, on this machine.",
    "",
    "* <span class=\"suggestion submit\" data-suggestion-submit=\"true\" title=\"Dawn tide\">What's the tide at dawn?</span>",
    "* <span class=\"suggestion submit\" data-suggestion-submit=\"true\" title=\"Field log\">Show the field log</span>",
    sep = "\n"
  ),
  footer = tags$p("Notes stay on this machine."),
  sidebar = chat_sidebar(
    tags$p(class = "small text-secondary mb-2", "A harbor log on glass."),
    textInput("project", "Project", "Harbor", width = "100%"),
    history = TRUE,
    width = 260,
    open = "open"
  ),
  toolbar = toolbar(
    toolbar_input_button("open_sources", "Sources")
  )
)

server <- function(input, output, session) {
  built <- make_client()
  client <- built$client
  live <- isTRUE(built$live)
  pace <- suppressWarnings(as.numeric(Sys.getenv("SHINYGLASS_CHAT_PACE", "0.11")))
  if (is.na(pace) || pace < 0) pace <- 0.11

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
    text <- user_text(input$chat_user_input)
    if (live) {
      chat_append("chat", client$stream_async(text, stream = "content"))
    } else {
      stream_pieces("chat", harbor_pieces(text), session, pace)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$chat_slash_command, {
    if (live) {
      chat_append("chat", client$stream_async("Save a short harbor note.", stream = "content"))
    } else {
      stream_pieces(
        "chat",
        list("Saved the note locally. It stays on this machine."),
        session,
        pace
      )
    }
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
}

app <- shinyApp(ui, server)
app
