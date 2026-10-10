# Harbor notes: the shinyglass chat demo.
# Local script by default. GEMINI_API_KEY or GOOGLE_API_KEY uses Gemini Flash.
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

# Prefer GEMINI_API_KEY. GOOGLE_API_KEY is the name ellmer also reads.
# The value is passed straight to ellmer and is never written to the log or UI.
# A staged .Renviron next to app.R is how shinyapps.io receives the key.
# readRenviron does not print values.
gemini_key <- function() {
  if (file.exists(".Renviron")) {
    tryCatch(
      suppressWarnings(readRenviron(".Renviron")),
      error = function(e) invisible(NULL)
    )
  }
  for (name in c("GEMINI_API_KEY", "GOOGLE_API_KEY")) {
    value <- Sys.getenv(name, "")
    if (nzchar(value)) return(value)
  }
  NULL
}

gemini_model <- function() {
  model <- Sys.getenv("SHINYGLASS_CHAT_MODEL", "gemini-3.7-flash")
  if (!nzchar(model)) "gemini-3.7-flash" else model
}

harbor_system_prompt <- function() {
  paste(
    "You are the shinyglass harbor guide.",
    "Answer in two or three sentences about shinyglass, Shiny, or R.",
    "If the question is off that topic, say so and point back to shinyglass."
  )
}

# Public demo limits. Over-long notes and extra turns stay on the local script.
chat_max_messages <- 8L
chat_max_chars <- 400L

gate_turn <- function(text, used, live,
                      max_messages = chat_max_messages,
                      max_chars = chat_max_chars) {
  text <- trimws(text %||% "")
  if (!nzchar(text)) {
    return(list(action = "ignore", text = text, used = used, notice = NULL))
  }
  if (nchar(text) > max_chars) {
    return(list(
      action = "too_long",
      text = "a shorter question",
      used = used,
      notice = "That note is a bit long for this public demo. Try a shorter question about shinyglass, Shiny, or R."
    ))
  }
  if (!isTRUE(live)) {
    return(list(action = "mock", text = text, used = used, notice = NULL))
  }
  if (used >= max_messages) {
    return(list(
      action = "capped",
      text = text,
      used = used,
      notice = "This session has used its free messages. Here is the local note instead."
    ))
  }
  list(action = "live", text = text, used = used + 1L, notice = NULL)
}

is_quota_error <- function(err) {
  if (inherits(err, "httr2_http_429")) return(TRUE)
  status <- NA_integer_
  for (field in c("status_code", "status")) {
    value <- tryCatch(err[[field]], error = function(e) NULL)
    if (is.numeric(value) && length(value) == 1L) {
      status <- as.integer(value)
      break
    }
  }
  if (identical(status, 429L)) return(TRUE)
  msg <- tryCatch(conditionMessage(err), error = function(e) "")
  grepl("429|RESOURCE_EXHAUSTED|quota|rate limit|too many requests", msg, ignore.case = TRUE)
}

api_notice <- function(err) {
  if (is_quota_error(err)) {
    "The live model is at its free-tier limit right now. Here is the local note instead."
  } else {
    "The live model could not answer just now. Here is the local note instead."
  }
}

mock_pieces <- function(text, notice = NULL) {
  pieces <- harbor_pieces(text)
  if (!is.null(notice) && nzchar(notice)) pieces <- c(list(notice), pieces)
  pieces
}

# Keep API failures inside the stream. chat_append would otherwise warn with
# the provider message, and that message can carry the request URL.
guarded_stream <- function(stream, text) {
  fallback <- NULL
  coro::gen({
    repeat {
      if (!is.null(fallback)) {
        if (!length(fallback)) break
        nxt <- fallback[[1]]
        fallback <<- fallback[-1]
        yield(nxt)
        next
      }
      piece <- tryCatch(stream(), error = function(e) e)
      if (coro::is_exhausted(piece)) break
      if (inherits(piece, "error")) {
        fallback <<- mock_pieces(text, api_notice(piece))
        next
      }
      if (promises::is.promise(piece)) {
        yield(promises::then(
          piece,
          onFulfilled = function(value) value,
          onRejected = function(err) {
            fallback <<- mock_pieces(text, NULL)
            api_notice(err)
          }
        ))
      } else {
        yield(piece)
      }
    }
  })
}

make_client <- function() {
  key <- gemini_key()
  if (is.null(key)) {
    return(list(client = make_echo_chat(), live = FALSE))
  }
  client <- tryCatch(
    ellmer::chat_google_gemini(
      system_prompt = harbor_system_prompt(),
      model = gemini_model(),
      api_key = key
    ),
    error = function(e) NULL
  )
  if (is.null(client)) {
    warning(
      "The Gemini client did not start. Using the local script.",
      call. = FALSE
    )
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
  # Public deploy: never echo raw API errors into the chat or the log.
  options(shiny.sanitize.errors = TRUE)

  built <- make_client()
  client <- built$client
  live <- isTRUE(built$live)
  pace <- suppressWarnings(as.numeric(Sys.getenv("SHINYGLASS_CHAT_PACE", "0.11")))
  if (is.na(pace) || pace < 0) pace <- 0.11
  used <- 0L

  send_mock <- function(text, notice = NULL) {
    stream_pieces("chat", mock_pieces(text, notice), session, pace)
  }

  start_live <- function(text) {
    started <- tryCatch(
      client$stream_async(text, stream = "content"),
      error = function(e) e
    )
    if (inherits(started, "error")) {
      send_mock(text, api_notice(started))
      return(invisible(NULL))
    }
    if (promises::is.promise(started)) {
      promises::then(
        started,
        onFulfilled = function(inner) {
          chat_append("chat", guarded_stream(inner, text))
        },
        onRejected = function(err) send_mock(text, api_notice(err))
      )
      return(invisible(NULL))
    }
    chat_append("chat", guarded_stream(started, text))
    invisible(NULL)
  }

  answer <- function(text) {
    decision <- gate_turn(user_text(text), used, live)
    used <<- decision$used
    if (identical(decision$action, "ignore")) return(invisible(NULL))
    if (identical(decision$action, "live")) {
      start_live(decision$text)
    } else {
      send_mock(decision$text, decision$notice)
    }
    invisible(NULL)
  }

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
    answer(input$chat_user_input)
  }, ignoreInit = TRUE)

  observeEvent(input$chat_slash_command, {
    if (live) {
      answer("Save a short harbor note about shinyglass.")
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
