# Harbor notes: the shinyglass chat demo.
# Local script by default. GEMINI_API_KEY or GOOGLE_API_KEY uses Gemini.
# The chain is gemini-3.5-flash-lite, then gemini-3.8-flash, then
# gemini-3.7-flash. SHINYGLASS_CHAT_MODEL is tried first when it is set.
# Web search stays off (the free tier cannot sustain grounding). Sources
# are the topic-matched pages. Thinking is requested when the model
# accepts it, and the disclosure appears only when thoughts come back.
#   shiny::runApp(system.file("examples/shinychat-glass", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)
library(shinychat)

local({
  hits <- file.path(getwd(), "phone-preview", "phone-preview.R")
  root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  for (i in seq_len(8L)) {
    hits <- c(
      hits,
      file.path(root, "inst", "examples", "_shared", "phone-preview.R"),
      file.path(root, "_shared", "phone-preview.R")
    )
    parent <- dirname(root)
    if (identical(parent, root)) break
    root <- parent
  }
  installed <- system.file("examples", "_shared", "phone-preview.R", package = "shinyglass")
  if (nzchar(installed)) hits <- c(hits, installed)
  hit <- hits[file.exists(hits)]
  if (!length(hit)) stop("Missing phone preview helper.", call. = FALSE)
  app_env <- parent.env(environment())
  assign(".phone_preview_dir", dirname(normalizePath(hit[[1L]], winslash = "/")), envir = app_env)
  sys.source(hit[[1L]], envir = app_env)
})

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

# Test stand-in for a live Gemini turn. Yields thinking and text, and no
# grounding citations, so the fallback has to attach topic-matched docs.
make_mock_live_chat <- function() {
  client <- make_echo_chat()
  client$stream_async <- function(..., stream = "content") {
    raw <- user_text(list(...))
    reply <- scripted_reply(raw)
    coro::gen({
      yield(ellmer::ContentThinking(reply$thinking))
      yield(ellmer::ContentText(reply$body))
    })
  }
  client
}

thinking_block <- function(text) {
  structure(text, class = "shinychat_thinking")
}

# Real pages a shinyglass or Shiny reply can cite. Each URL is public.
docs_citations <- function() {
  list(
    list(
      title = "shinyglass docs",
      url = "https://ericrayanderson.github.io/shinyglass/",
      note = "Theme, tokens, and the glass API."
    ),
    list(
      title = "shinyglass README",
      url = "https://github.com/ericrayanderson/shinyglass",
      note = "Install, screenshots, and the Harbor notes demo."
    ),
    list(
      title = "Apple HIG materials",
      url = "https://developer.apple.com/design/human-interface-guidelines/materials",
      note = "How materials sit over content."
    ),
    list(
      title = "Adopting Liquid Glass",
      url = "https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass",
      note = "Apple's Liquid Glass overview."
    ),
    list(
      title = "Shiny docs",
      url = "https://shiny.posit.co/",
      note = "Shiny for R, from the first app onward."
    ),
    list(
      title = "shinychat",
      url = "https://posit-dev.github.io/shinychat/",
      note = "The chat component this demo styles."
    )
  )
}

# Our own pill. shinychat turns <shiny-aside> into an image whose src is
# icons.duckduckgo.com, and a stored copy of that markup keeps requesting it.
source_host <- function(url) {
  host <- tolower(trimws(url %||% ""))
  host <- sub("^https?://", "", host)
  host <- sub("/.*$", "", host)
  host <- sub(":.*$", "", host)
  sub("^www\\.", "", host)
}

source_kind <- function(url) {
  host <- source_host(url)
  if (grepl("apple.com", host, fixed = TRUE)) return("apple")
  if (grepl("posit", host, fixed = TRUE)) return("posit")
  if (identical(host, "github.com") || endsWith(host, ".github.com")) return("github")
  if (grepl("github.io", host, fixed = TRUE) || grepl("docs", host, fixed = TRUE) || grepl("tidyverse.org", host, fixed = TRUE)) {
    return("docs")
  }
  "mark"
}

source_icon_svg <- function(url, title = "") {
  kind <- source_kind(url)
  inner <- switch(
    kind,
    apple = "<path fill='#fff' d='M8.1 2.8c.2 1 .9 1.6 1.8 1.7C9.7 5.8 8.8 6.8 8.1 6.8S6.5 5.8 6.3 4.5c.8-.1 1.6-.8 1.8-1.7z'/><path fill='#fff' d='M8 6.5c1.7 0 2.7 1.1 2.7 2.7 0 1.9-1.2 3.8-2.7 3.8S5.3 11.1 5.3 9.2C5.3 7.6 6.3 6.5 8 6.5z'/>",
    github = "<circle cx='5' cy='4.8' r='1.25' fill='#fff'/><circle cx='11' cy='4.8' r='1.25' fill='#fff'/><circle cx='8' cy='11.2' r='1.25' fill='#fff'/><path d='M5 6.1v2.1c0 1 .9 1.6 3 1.6h3V6.1' fill='none' stroke='#fff' stroke-width='1.15'/>",
    posit = "<circle cx='8' cy='8' r='3.15' fill='none' stroke='#fff' stroke-width='1.45'/><circle cx='8' cy='8' r='1.15' fill='#fff'/>",
    docs = "<path fill='#fff' d='M3.2 3.1h4.3c.9 0 1.6.7 1.6 1.6v7.5H5.1c-1.1 0-1.9.8-1.9 1.9V3.1z'/><path fill='#dbe4ff' d='M8.3 3.1h4.5v8.3H8.3c-.7 0-1.3-.6-1.3-1.3V4.4c0-.7.6-1.3 1.3-1.3z'/>",
    {
      host <- source_host(url)
      letter <- toupper(substr(host, 1L, 1L))
      if (!nzchar(letter)) letter <- "?"
      letter <- htmltools::htmlEscape(letter, attribute = TRUE)
      sprintf(
        "<text x='8' y='11.2' text-anchor='middle' font-family='system-ui,sans-serif' font-size='9' font-weight='700' fill='#fff'>%s</text>",
        letter
      )
    }
  )
  bg <- switch(
    kind,
    apple = "#1d1d1f",
    github = "#24292f",
    posit = "#447099",
    docs = "#3b5bdb",
    "#5c6770"
  )
  sprintf(
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' aria-hidden='true'><rect width='16' height='16' rx='4' fill='%s'/>%s</svg>",
    bg,
    inner
  )
}

source_icon_span <- function(url, class = "harbor-pill-icon") {
  tags$span(class = class, HTML(source_icon_svg(url)))
}

source_pills_html <- function(items) {
  items <- unique_cites(items)
  if (!length(items)) return(NULL)
  tags$div(
    class = "harbor-pills",
    lapply(items, function(item) {
      tags$a(
        class = "harbor-pill",
        href = item$url,
        target = "_blank",
        rel = "noopener noreferrer",
        source_icon_span(item$url),
        tags$span(class = "harbor-pill-label", item$title %||% item$url)
      )
    })
  )
}

harbor_question <- function(text) {
  grepl("tide|harbor|harbour|dawn|field log", text %||% "", ignore.case = TRUE)
}

chat_question <- function(text) {
  grepl("chat|shinychat|composer|bubble", text %||% "", ignore.case = TRUE)
}

# Scripted answers follow the question. Tide notes stay a side path and
# do not cite the shinyglass docs. Everything else stays on Shiny.
scripted_reply <- function(text) {
  if (harbor_question(text)) {
    return(list(
      thinking = "Checking the harbor log for dawn.",
      body = "Dawn at the harbor is quiet. High tide is 1.4 m at 06:10, and the water is already turning.",
      citations = list(),
      tool = tide_block()
    ))
  }
  cites <- docs_citations()
  if (chat_question(text)) {
    return(list(
      thinking = "Checking how a Shiny chat picks up glass.",
      body = paste(
        "Pass theme = glass_theme() to page_chat().",
        "The composer, bubbles, and sidebar then share the same Liquid Glass material as the rest of the app."
      ),
      citations = cites[c(6L, 1L, 5L)],
      tool = NULL
    ))
  }
  list(
    thinking = "Looking through the shinyglass theme API.",
    body = paste(
      "glass_theme() builds a Liquid Glass bslib theme.",
      "Choose a preset, a scene, and an intensity, and inputs, cards, and chat use the same material."
    ),
    citations = cites,
    tool = theme_block()
  )
}

# Curated pages for a live reply that came back without grounding.
# Tide-only notes stay empty. Glass, chat, and Shiny questions each
# get the docs that match that topic.
curated_citations <- function(text) {
  cites <- docs_citations()
  blob <- paste(text %||% "", collapse = " ")
  glass <- grepl(
    "glass|theme|liquid|preset|scene|intensity|material|shinyglass",
    blob,
    ignore.case = TRUE
  )
  chat <- chat_question(blob)
  shiny <- grepl("shiny|bslib", blob, ignore.case = TRUE)
  if (!glass && !chat && !shiny) return(list())
  picked <- list()
  if (glass) picked <- c(picked, cites[c(1L, 2L, 3L, 4L, 5L)])
  if (chat) picked <- c(picked, cites[c(6L, 1L, 5L)])
  if (shiny && !glass && !chat) picked <- c(picked, cites[c(5L, 1L, 6L)])
  out <- list()
  seen <- character()
  for (item in picked) {
    if (is.null(item$url) || item$url %in% seen) next
    seen <- c(seen, item$url)
    out[[length(out) + 1L]] <- item
  }
  out
}

chunk_words <- function(body) {
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
  as.list(chunks)
}

# The notice is a toast beside the transcript, never a chunk of the answer.
# Keeping it out of these pieces is what stops "local note instead.glass_theme()"
# after a reload.
reply_pieces <- function(reply, notice = NULL) {
  pieces <- c(
    list(thinking_block(reply$thinking)),
    chunk_words(reply$body)
  )
  if (!is.null(reply$tool)) pieces <- c(pieces, list(reply$tool))
  pills <- source_pills_html(reply$citations)
  if (!is.null(pills)) pieces <- c(pieces, list(pills))
  pieces
}

# v1 stored the whole bubble, so the toast was glued to the answer and the
# collapsed pill survived as "shinyglass docs +5" or as duckduckgo markup.
notice_catalog <- function() {
  c(
    "The live model is at its free-tier limit right now. Here is the local note instead.",
    "The live model could not answer just now. Here is the local note instead.",
    "This session has used its free messages. Here is the local note instead.",
    "That note is a bit long for this public demo. Try a shorter question about shinyglass, Shiny, or R."
  )
}

rx_escape <- function(text) {
  gsub("([][{}()+*^$|\\\\.?])", "\\\\\\1", text, perl = TRUE)
}

unique_cites <- function(items) {
  out <- list()
  seen <- character()
  if (is.null(items)) return(out)
  for (item in items) {
    if (is.null(item) || !is.list(item)) next
    url <- item$url %||% ""
    url <- paste(as.character(url), collapse = "")
    if (!nzchar(url)) next
    if (grepl("duckduckgo.com", url, fixed = TRUE)) next
    if (url %in% seen) next
    seen <- c(seen, url)
    title <- item$title %||% ""
    title <- paste(as.character(title), collapse = "")
    note <- item$note %||% ""
    note <- paste(as.character(note), collapse = "")
    out[[length(out) + 1L]] <- list(
      title = if (nzchar(title)) title else url,
      url = url,
      note = note
    )
  }
  out
}

decode_cite_json <- function(text) {
  text <- paste(text %||% "", collapse = "")
  if (!nzchar(text) || identical(text, "[]")) return(list())
  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (is.null(parsed) || !length(parsed)) return(list())
  if (!is.null(parsed$url) || !is.null(parsed$title)) parsed <- list(parsed)
  lapply(parsed, function(item) {
    if (!is.list(item)) return(NULL)
    list(
      title = paste(as.character(item$title %||% ""), collapse = ""),
      url = paste(as.character(item$url %||% ""), collapse = ""),
      note = paste(as.character(item$note %||% ""), collapse = "")
    )
  })
}

split_glued_notice <- function(text) {
  text <- paste(text %||% "", collapse = "\n")
  for (note in notice_catalog()) {
    if (startsWith(text, note)) {
      return(list(text = substring(text, nchar(note) + 1L), notice = note))
    }
  }
  list(text = text, notice = "")
}

extract_aside_cites <- function(text) {
  cites <- list()
  if (!grepl("shiny-aside", text, fixed = TRUE)) {
    return(list(text = text, citations = cites))
  }
  tags_found <- regmatches(
    text,
    gregexpr("<shiny-aside\\b[^>]*>", text, perl = TRUE, ignore.case = TRUE)
  )[[1]]
  for (tag in tags_found) {
    label <- if (grepl("\\blabel\\s*=\\s*\"", tag, perl = TRUE)) {
      sub(".*\\blabel\\s*=\\s*\"([^\"]*)\".*", "\\1", tag, perl = TRUE)
    } else {
      ""
    }
    url <- if (grepl("\\burl\\s*=\\s*\"", tag, perl = TRUE)) {
      sub(".*\\burl\\s*=\\s*\"([^\"]*)\".*", "\\1", tag, perl = TRUE)
    } else {
      ""
    }
    if (nzchar(url)) {
      cites[[length(cites) + 1L]] <- list(title = label, url = url, note = "")
    }
  }
  text <- gsub(
    "<shiny-aside\\b[^>]*>.*?</shiny-aside>",
    " ",
    text,
    perl = TRUE,
    ignore.case = TRUE
  )
  text <- gsub("<shiny-aside\\b[^>]*/?>", " ", text, perl = TRUE, ignore.case = TRUE)
  list(text = text, citations = cites)
}

strip_duckduckgo <- function(text) {
  text <- gsub("<img\\b[^>]*duckduckgo\\.com[^>]*>", " ", text, perl = TRUE, ignore.case = TRUE)
  text <- gsub("https?://icons\\.duckduckgo\\.com[^[:space:]\"'<>]*", " ", text, perl = TRUE, ignore.case = TRUE)
  text <- gsub("https?://[^[:space:]\"'<>]*gstatic\\.com/favicon[^[:space:]\"'<>]*", " ", text, perl = TRUE, ignore.case = TRUE)
  text
}

# Only a trailing "Title +N" run is a collapsed pill. A title inside the
# answer, with no trailing count, stays put.
strip_trailing_source_labels <- function(text) {
  catalog <- docs_citations()
  titles <- vapply(catalog, function(item) item$title, character(1))
  found <- list()
  if (!grepl("\\+\\d+\\s*$", text, perl = TRUE)) {
    return(list(text = text, citations = found))
  }
  repeat {
    hit <- FALSE
    for (i in seq_along(titles)) {
      pat <- paste0("\\s+", rx_escape(titles[[i]]), "\\s+\\+\\d+\\s*$")
      if (grepl(pat, text, perl = TRUE)) {
        text <- sub(pat, "", text, perl = TRUE)
        found <- c(list(catalog[[i]]), found)
        hit <- TRUE
        break
      }
    }
    if (!hit && grepl("\\s*\\+\\d+\\s*$", text, perl = TRUE)) {
      stripped <- sub("\\s*\\+\\d+\\s*$", "", text, perl = TRUE)
      local <- list()
      repeat {
        title_hit <- FALSE
        for (i in seq_along(titles)) {
          pat <- paste0("\\s+", rx_escape(titles[[i]]), "\\s*$")
          if (grepl(pat, stripped, perl = TRUE)) {
            stripped <- sub(pat, "", stripped, perl = TRUE)
            local <- c(list(catalog[[i]]), local)
            title_hit <- TRUE
            break
          }
        }
        if (!title_hit) break
      }
      text <- stripped
      if (length(local)) found <- c(local, found)
      hit <- TRUE
    }
    if (!hit) break
  }
  list(text = text, citations = found)
}

cites_from_parallel <- function(titles, urls, notes) {
  titles <- as.character(unlist(titles, use.names = FALSE))
  urls <- as.character(unlist(urls, use.names = FALSE))
  notes <- as.character(unlist(notes, use.names = FALSE))
  n <- max(length(titles), length(urls), length(notes))
  if (!n) return(list())
  lapply(seq_len(n), function(i) {
    list(
      title = if (i <= length(titles)) titles[[i]] else "",
      url = if (i <= length(urls)) urls[[i]] else "",
      note = if (i <= length(notes)) notes[[i]] else ""
    )
  })
}

coerce_messages <- function(messages) {
  if (is.null(messages) || !length(messages)) return(list())
  if (is.data.frame(messages)) {
    n <- nrow(messages)
    if (!n) return(list())
    return(lapply(seq_len(n), function(i) {
      raw <- if (!is.null(messages$citations)) messages$citations[[i]] else list()
      if (is.character(raw)) raw <- decode_cite_json(raw[[1]])
      list(
        role = as.character(messages$role[[i]]),
        text = as.character(messages$text[[i]]),
        thinking = if (!is.null(messages$thinking)) as.character(messages$thinking[[i]] %||% "") else "",
        citations = if (is.list(raw)) raw else list()
      )
    }))
  }
  if (!is.null(messages$role) && !is.list(messages[[1L]])) {
    raw <- messages$citations
    if (is.character(raw)) raw <- decode_cite_json(paste(raw, collapse = ""))
    return(list(list(
      role = as.character(messages$role[[1]]),
      text = as.character(messages$text[[1]] %||% ""),
      thinking = as.character(messages$thinking[[1]] %||% ""),
      citations = if (is.list(raw)) raw else list()
    )))
  }
  lapply(messages, function(msg) {
    if (!is.list(msg)) return(NULL)
    raw <- msg$citations
    if (is.character(raw)) raw <- decode_cite_json(paste(raw, collapse = ""))
    list(
      role = as.character(msg$role %||% ""),
      text = paste(as.character(msg$text %||% ""), collapse = "\n"),
      thinking = paste(as.character(msg$thinking %||% ""), collapse = "\n"),
      citations = if (is.list(raw)) raw else list()
    )
  })
}

messages_from_payload <- function(data) {
  if (!is.list(data)) return(list())
  if (!is.null(data$messages)) return(coerce_messages(data$messages))
  roles <- data$role
  texts <- data$text
  if (is.null(roles) || is.null(texts)) return(list())
  roles <- as.character(unlist(roles, use.names = FALSE))
  texts <- as.character(unlist(texts, use.names = FALSE))
  n <- min(length(roles), length(texts))
  if (!n) return(list())
  thinkings <- data$thinking
  if (is.null(thinkings)) thinkings <- rep("", n)
  thinkings <- as.character(unlist(thinkings, use.names = FALSE))
  if (length(thinkings) < n) thinkings <- c(thinkings, rep("", n - length(thinkings)))
  raw_cites <- data$msg_citations
  if (is.null(raw_cites)) raw_cites <- rep("", n)
  raw_cites <- as.character(unlist(raw_cites, use.names = FALSE))
  lapply(seq_len(n), function(i) {
    list(
      role = roles[[i]],
      text = texts[[i]],
      thinking = thinkings[[i]],
      citations = decode_cite_json(if (i <= length(raw_cites)) raw_cites[[i]] else "")
    )
  })
}

# Storage v3 keeps the toast, the answer, and per-message citations apart.
# Older transcripts are rewritten here. A message that becomes empty is dropped.
migrate_stored_transcript <- function(data) {
  empty <- list(v = 3L, messages = list(), citations = list(), notice = "")
  if (!is.list(data)) return(empty)
  messages <- messages_from_payload(data)
  globals <- unique_cites(data$citations)
  if (!length(globals) && !is.null(data$cite_url)) {
    globals <- unique_cites(cites_from_parallel(data$cite_title, data$cite_url, data$cite_note))
  }
  notice <- data$notice %||% ""
  if (is.list(notice)) notice <- if (length(notice)) notice[[1L]] else ""
  notice <- paste(as.character(notice), collapse = "")
  if (identical(notice, "NULL") || is.na(notice)) notice <- ""
  cleaned <- list()
  for (msg in messages) {
    if (is.null(msg) || !msg$role %in% c("user", "assistant")) next
    split <- split_glued_notice(msg$text)
    if (nzchar(split$notice)) notice <- split$notice
    text <- split$text
    aside <- extract_aside_cites(text)
    text <- strip_duckduckgo(aside$text)
    tail <- strip_trailing_source_labels(text)
    text <- trimws(gsub("[[:space:]]+", " ", tail$text))
    cites <- unique_cites(c(msg$citations, aside$citations, tail$citations))
    if (!nzchar(text)) next
    cleaned[[length(cleaned) + 1L]] <- list(
      role = msg$role,
      text = text,
      thinking = msg$thinking %||% "",
      citations = cites
    )
  }
  if (length(globals)) {
    idx <- which(vapply(cleaned, function(msg) identical(msg$role, "assistant"), logical(1)))
    if (length(idx)) {
      last <- idx[[length(idx)]]
      cleaned[[last]]$citations <- unique_cites(c(cleaned[[last]]$citations, globals))
    }
  }
  panel <- globals
  if (!length(panel)) {
    for (msg in cleaned) panel <- unique_cites(c(panel, msg$citations))
  }
  list(v = 3L, messages = cleaned, citations = panel, notice = notice)
}

harbor_fallback_requested <- function(query = "") {
  if (identical(Sys.getenv("SHINYGLASS_CHAT_FORCE_FALLBACK"), "1")) return(TRUE)
  q <- paste(query %||% "", collapse = "")
  grepl("(^|[?&])harbor_fallback=1(?:&|$)", q)
}

theme_block <- function() {
  structure(
    list(
      type = "tool_result",
      version = 1L,
      request_id = "theme-1",
      tool_name = "glass_theme",
      status = "success",
      title = "Read glass_theme",
      label = "shinyglass",
      value_preview = "preset, scene, intensity",
      value = "glass_theme(preset, scene, intensity) builds the Liquid Glass theme.",
      show_request = FALSE,
      expanded = TRUE,
      open_style = "framed"
    ),
    class = c("shinychat_tool_result", "shinychat_tool_card", "shinychat_block")
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

# Tried in order on 503, 429, and 404. An override is first, then the
# rest of the chain, without repeating a model.
gemini_model_chain <- function() {
  override <- Sys.getenv("SHINYGLASS_CHAT_MODEL", "")
  defaults <- c(
    "gemini-3.5-flash-lite",
    "gemini-3.8-flash",
    "gemini-3.7-flash"
  )
  models <- if (nzchar(override)) c(override, defaults) else defaults
  unique(models[nzchar(models)])
}

gemini_model <- function() {
  chain <- gemini_model_chain()
  if (!length(chain)) "gemini-3.5-flash-lite" else chain[[1L]]
}

harbor_system_prompt <- function() {
  paste(
    "You answer questions about shinyglass, Shiny, and R, and ordinary conversation.",
    "shinyglass is Liquid Glass themes for Shiny, matching Apple iOS 27.",
    "glass_theme() and glass_page() build the theme.",
    "Intensity is 0 to 1, default 0.5, via glass_intensity_slider().",
    "It has refraction, morphing, and press physics, plus fallbacks for reduced transparency, increased contrast, and forced colors.",
    "shinychat page_chat() and bslib offcanvas() are supported, and so are the React components.",
    "Answer in 2 to 4 short paragraphs, or one short code snippet.",
    "Stay specific to these APIs.",
    "Name the project or the document you rely on.",
    "Decline only a clearly unrelated or abusive request, in one short sentence, without role-play."
  )
}

# Public demo limits. Over-long notes and extra turns stay on the local script.
# The phone preview is a second session, so the 8 live messages are a
# visitor budget in localStorage, shared by the page and the iframe.
chat_max_messages <- 8L
chat_max_chars <- 400L

harbor_turn_budget <- function(used, visitor) {
  one <- function(value) {
    if (is.null(value) || !length(value)) return(0L)
    n <- suppressWarnings(as.integer(value[[1L]]))
    if (length(n) != 1L || is.na(n) || n < 0L) 0L else n
  }
  max(one(used), one(visitor))
}

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

error_status <- function(err) {
  classes <- class(err)
  hit <- grep("^httr2_http_[0-9]+$", classes, value = TRUE)
  if (length(hit)) return(as.integer(sub("httr2_http_", "", hit[[1L]])))
  for (field in c("status_code", "status")) {
    value <- tryCatch(err[[field]], error = function(e) NULL)
    if (is.numeric(value) && length(value) == 1L && !is.na(value)) {
      return(as.integer(value))
    }
  }
  resp <- tryCatch(err$resp, error = function(e) NULL)
  if (!is.null(resp)) {
    status <- tryCatch(httr2::resp_status(resp), error = function(e) NA_integer_)
    if (is.numeric(status) && length(status) == 1L && !is.na(status)) {
      return(as.integer(status))
    }
  }
  msg <- tryCatch(conditionMessage(err), error = function(e) "")
  found <- regexpr("\\b(400|404|429|500|503)\\b", msg)
  if (found > 0L) return(as.integer(regmatches(msg, found)))
  NA_integer_
}

is_quota_error <- function(err) {
  if (identical(error_status(err), 429L)) return(TRUE)
  msg <- tryCatch(conditionMessage(err), error = function(e) "")
  grepl("RESOURCE_EXHAUSTED|quota|rate limit|too many requests", msg, ignore.case = TRUE)
}

# 503 high demand, 429 quota, and 404 (model hidden from new projects)
# are the reasons to try the next model. Anything else stops the chain.
is_capacity_error <- function(err) {
  status <- error_status(err)
  if (!is.na(status) && status %in% c(404L, 429L, 503L)) return(TRUE)
  msg <- tryCatch(conditionMessage(err), error = function(e) "")
  grepl(
    "RESOURCE_EXHAUSTED|NOT_FOUND|high demand|quota|rate limit|too many requests|not available|unavailable",
    msg,
    ignore.case = TRUE
  )
}

# Flash-lite may reject a thinking budget. Retry that same model once
# without thinking params instead of treating it as a dead model.
is_thinking_error <- function(err) {
  status <- error_status(err)
  if (!is.na(status) && status != 400L) return(FALSE)
  msg <- tryCatch(conditionMessage(err), error = function(e) "")
  grepl("thinking|thoughts|reasoning", msg, ignore.case = TRUE)
}

chain_decision <- function(err, plain = FALSE) {
  if (is.null(err)) return("fail")
  if (is_thinking_error(err) && !isTRUE(plain)) return("retry_plain")
  if (is_capacity_error(err)) return("next")
  "fail"
}

chain_attempt <- function(attempt, model, params) {
  result <- tryCatch(attempt(model, params), error = function(e) e)
  if (inherits(result, "error")) return(list(ok = FALSE, err = result))
  if (is.list(result) && isTRUE(result$ok)) return(list(ok = TRUE, err = NULL))
  if (is.list(result) && inherits(result$err, "error")) {
    return(list(ok = FALSE, err = result$err))
  }
  list(ok = FALSE, err = simpleError("model attempt failed"))
}

# Pure walk used by the live client and by tests. `attempt(model, params)`
# returns list(ok = TRUE) or an error (thrown or as list(ok = FALSE, err = )).
walk_model_chain <- function(models, attempt) {
  last_err <- NULL
  for (model in models) {
    outcome <- chain_attempt(attempt, model, gemini_params(model))
    if (isTRUE(outcome$ok)) {
      return(list(ok = TRUE, model = model, thinking = TRUE, notice = NULL, err = NULL))
    }
    last_err <- outcome$err
    if (identical(chain_decision(last_err, FALSE), "retry_plain")) {
      outcome <- chain_attempt(attempt, model, NULL)
      if (isTRUE(outcome$ok)) {
        return(list(ok = TRUE, model = model, thinking = FALSE, notice = NULL, err = NULL))
      }
      last_err <- outcome$err
    }
    if (!identical(chain_decision(last_err, TRUE), "next")) break
  }
  list(
    ok = FALSE,
    model = NA_character_,
    thinking = FALSE,
    notice = if (is.null(last_err)) {
      "The live model could not answer just now. Here is the local note instead."
    } else {
      api_notice(last_err)
    },
    err = last_err
  )
}

api_notice <- function(err) {
  if (is_quota_error(err)) {
    "The live model is at its free-tier limit right now. Here is the local note instead."
  } else {
    "The live model could not answer just now. Here is the local note instead."
  }
}

mock_pieces <- function(text, notice = NULL) {
  reply_pieces(scripted_reply(text), notice)
}

# Keep API failures inside the stream. chat_append would otherwise warn with
# the provider message, and that message can carry the request URL.
guarded_stream <- function(stream, text, on_fallback = NULL) {
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
        notice <- api_notice(piece)
        if (is.function(on_fallback)) on_fallback(notice)
        fallback <<- mock_pieces(text, NULL)
        next
      }
      if (promises::is.promise(piece)) {
        yield(promises::then(
          piece,
          onFulfilled = function(value) value,
          onRejected = function(err) {
            notice <- api_notice(err)
            if (is.function(on_fallback)) on_fallback(notice)
            pieces <- mock_pieces(text, NULL)
            if (!length(pieces)) return("")
            fallback <<- if (length(pieces) > 1L) pieces[-1L] else list()
            pieces[[1L]]
          }
        ))
      } else {
        yield(piece)
      }
    }
  })
}

# Gemini 3, including flash-lite, takes a thinking level. ellmer turns that
# into thinkingConfig with includeThoughts, so a summary can show as
# "Thought for ...". Flash-lite may still return none; that is fine.
# Older flash-lite builds take a small token budget. Other older models
# take a larger budget. A 400 from thinking retries the same model with
# params = NULL.
gemini_params <- function(model = gemini_model()) {
  model <- model %||% ""
  if (grepl("^gemini-3", model)) {
    ellmer::params(reasoning_effort = "low")
  } else if (grepl("flash-lite", model, fixed = TRUE)) {
    ellmer::params(reasoning_tokens = 256L)
  } else {
    ellmer::params(reasoning_tokens = 1024L)
  }
}

new_gemini_client <- function(key, model, params = gemini_params(model)) {
  ellmer::chat_google_gemini(
    system_prompt = harbor_system_prompt(),
    model = model,
    api_key = key,
    params = params
  )
}

make_client <- function() {
  models <- gemini_model_chain()
  if (identical(Sys.getenv("SHINYGLASS_CHAT_MOCK_LIVE"), "1")) {
    return(list(client = make_mock_live_chat(), live = TRUE, key = NULL, models = models))
  }
  key <- gemini_key()
  if (is.null(key)) {
    return(list(client = make_echo_chat(), live = FALSE, key = NULL, models = models))
  }
  client <- tryCatch(
    new_gemini_client(key, models[[1L]], gemini_params(models[[1L]])),
    error = function(e) NULL
  )
  if (is.null(client)) {
    warning(
      "The Gemini client did not start. Using the local script.",
      call. = FALSE
    )
    return(list(client = make_echo_chat(), live = FALSE, key = NULL, models = models))
  }
  list(client = client, live = TRUE, key = key, models = models)
}

# Green only after a reply that actually came from the model.
# Amber when the session is on the local script.
harbor_status_ui <- function(mode = c("ready", "live", "demo")) {
  mode <- match.arg(mode)
  if (identical(mode, "demo")) {
    tags$span(class = "harbor-status", `data-mode` = "demo", "Demo replies")
  } else if (identical(mode, "live")) {
    tags$span(class = "harbor-status", `data-mode` = "live", "Live (Gemini)")
  } else {
    tags$span(class = "harbor-status", `data-mode` = "ready", "Live (Gemini)")
  }
}

# Inline droplet. A file href would follow shinyapps' worker <base> and 404
# (_w_<token>/favicon.ico), and the origin root is not this app's www/.
harbor_icon_src <- function() {
  paste0(
    "data:image/svg+xml;base64,",
    "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAzMiAzMiI+",
    "CiAgPGRlZnM+CiAgICA8bGluZWFyR3JhZGllbnQgaWQ9ImciIHgxPSI4IiB5MT0iMiIgeDI9IjI0IiB5Mj0iMzAiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4K",
    "ICAgICAgPHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjRThGM0ZGIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iMC40NSIgc3RvcC1jb2xvcj0iIzdDQjhGRiIvPgog",
    "ICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMwMDdBRkYiLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgPC9kZWZzPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0",
    "PSIzMiIgcng9IjgiIGZpbGw9IiMwQjFDMzMiLz4KICA8cGF0aCBmaWxsPSJ1cmwoI2cpIiBkPSJNMTYgNC4yYy0zLjYgNS4yLTguMiA4LjgtOC4yIDE0LjFhOC4yIDguMiAwIDAg",
    "MCAxNi40IDBjMC01LjMtNC42LTguOS04LjItMTQuMXoiLz4KICA8ZWxsaXBzZSBjeD0iMTMuMSIgY3k9IjE2LjIiIHJ4PSIyLjIiIHJ5PSIzLjEiIGZpbGw9IiNmZmYiIG9wYWNpdHk9",
    "IjAuNzIiLz4KPC9zdmc+Cg=="
  )
}

normalize_restore <- function(payload) {
  if (!is.list(payload)) return(list())
  roles <- payload$role
  texts <- payload$text
  if (is.null(roles) || is.null(texts)) {
    msgs <- payload$messages
    if (is.data.frame(msgs)) {
      roles <- msgs$role
      texts <- msgs$text
    }
  }
  if (is.null(roles) || is.null(texts)) return(list())
  roles <- as.character(unlist(roles, use.names = FALSE))
  texts <- as.character(unlist(texts, use.names = FALSE))
  n <- min(length(roles), length(texts))
  if (!n) return(list())
  thinkings <- payload$thinking
  if (is.null(thinkings) && is.data.frame(payload$messages)) {
    thinkings <- payload$messages$thinking
  }
  if (is.null(thinkings)) thinkings <- rep("", n)
  thinkings <- as.character(unlist(thinkings, use.names = FALSE))
  if (length(thinkings) < n) {
    thinkings <- c(thinkings, rep("", n - length(thinkings)))
  }
  lapply(seq_len(n), function(i) {
    list(role = roles[[i]], text = texts[[i]], thinking = thinkings[[i]])
  })
}

restore_notice <- function(payload) {
  notice <- payload$notice %||% ""
  if (is.list(notice)) notice <- if (length(notice)) notice[[1L]] else ""
  notice <- as.character(notice)
  if (!length(notice) || is.na(notice[[1L]])) return("")
  notice[[1L]]
}

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark", "auto")
)

harbor_page <- tagList(
  tags$head(
    tags$script(HTML("
      (function () {
        var KEY = 'shinyglass-harbor-turns';
        function read() {
          try {
            var n = parseInt(localStorage.getItem(KEY) || '0', 10);
            return isFinite(n) && n > 0 ? Math.floor(n) : 0;
          } catch (e) {
            return 0;
          }
        }
        function report() {
          if (!window.Shiny || !Shiny.setInputValue) return;
          Shiny.setInputValue('harbor_visitor_turns', read(), {priority: 'event'});
        }
        function save(n) {
          if (!isFinite(n) || n < 0) return;
          try { localStorage.setItem(KEY, String(Math.floor(n))); } catch (e) {}
        }
        function bind() {
          if (!window.Shiny || bind.done) return;
          bind.done = true;
          Shiny.addCustomMessageHandler('harbor-turns-save', function (msg) {
            save(msg && msg.used);
          });
          report();
        }
        document.addEventListener('shiny:connected', function () {
          bind();
          report();
        });
        window.addEventListener('storage', function (e) {
          if (e.key === KEY) report();
        });
        if (window.Shiny) bind();
      })();
    ")),
    tags$link(rel = "icon", type = "image/svg+xml", href = harbor_icon_src()),
    tags$style(HTML("
      .harbor-mark { display: block; width: 22px; height: 22px; }
      /* Toast under the chat header, over the transcript only. It must not
         cover the sidebar or the sources offcanvas, grow the page, or take
         clicks outside the toast itself. */
      #harbor_notice_host {
        position: absolute;
        z-index: 2;
        top: 0.35rem;
        left: 0;
        right: 0;
        width: min(40rem, 100%);
        margin: 0 auto;
        padding: 0 16px;
        box-sizing: border-box;
        pointer-events: none;
        display: flex;
        justify-content: center;
      }
      .harbor-notice {
        pointer-events: auto;
        display: flex;
        align-items: flex-start;
        gap: 0.55rem;
        width: 100%;
        margin: 0;
        padding: 0.65rem 0.55rem 0.65rem 0.95rem;
        border-radius: 1rem;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 88%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight), 0 12px 32px var(--glass-shadow);
        backdrop-filter: blur(18px) saturate(var(--glass-saturate));
        -webkit-backdrop-filter: blur(18px) saturate(var(--glass-saturate));
      }
      .harbor-notice.is-hidden { display: none; }
      .harbor-notice-copy { margin: 0; flex: 1 1 auto; }
      .harbor-notice-dismiss {
        pointer-events: auto;
        flex: 0 0 auto;
        width: 32px;
        height: 32px;
        margin: 0;
        padding: 0;
        border: 0;
        border-radius: 999px;
        background: transparent;
        color: inherit;
        cursor: pointer;
        line-height: 1;
      }
      html.harbor-notes body::before {
        animation: harbor-orb-intro 2.2s ease-out 1 forwards;
      }
      html.harbor-notes body::after {
        animation: harbor-orb-intro 2.6s ease-out 1 forwards;
      }
      @keyframes harbor-orb-intro {
        0% { transform: translate3d(0.45%, -0.3%, 0) scale(1.012); }
        100% { transform: translate3d(0, 0, 0) scale(1); }
      }
      html.harbor-notes .shiny-chat-page-header,
      html.harbor-notes .shiny-chat-page-sidebar,
      html.harbor-notes .shiny-chat-page-sidebar-scrim,
      html.harbor-notes .shiny-chat-composer,
      html.harbor-notes .shiny-chat-btn-send,
      html.harbor-notes .shiny-chat-edit-btn,
      html.harbor-notes .shiny-chat-page-sidebar-toggle,
      html.harbor-notes .shiny-chat-page-sidebar-close,
      html.harbor-notes bslib-input-dark-mode,
      html.harbor-notes .bslib-toolbar .btn,
      html.harbor-notes .shiny-chat-history-itemmenu,
      html.harbor-notes .shiny-chat-history-itemmenu > button,
      html.harbor-notes .shiny-chat-history-close {
        animation: none !important;
        transition: none !important;
      }
      html.harbor-notes bslib-input-dark-mode {
        --speed-fast: 0s;
        --speed-normal: 0s;
      }
      @media (prefers-reduced-motion: reduce) {
        html.harbor-notes body::before,
        html.harbor-notes body::after {
          animation: none !important;
          transform: none !important;
        }
        html.harbor-notes .shiny-chat-page-header,
        html.harbor-notes .shiny-chat-composer,
        html.harbor-notes .shiny-chat-btn-send,
        html.harbor-notes .shiny-chat-edit-btn,
        html.harbor-notes .shiny-chat-page-sidebar-toggle,
        html.harbor-notes .bslib-toolbar .btn {
          animation: none !important;
          transition: none !important;
        }
      }
      html.harbor-notes .shiny-aside-pill img[src*='duckduckgo'],
      html.harbor-notes .shiny-aside-pill img[src*='favicon'] {
        visibility: hidden;
      }
      .harbor-footer-row {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: center;
        gap: 0.45rem;
      }
      .harbor-status {
        display: inline-flex;
        align-items: center;
        min-height: 1.4rem;
        padding: 0.1rem 0.55rem;
        border-radius: 999px;
        font-size: 0.72rem;
        letter-spacing: 0.01em;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 82%, transparent);
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight);
      }
      .harbor-status[data-mode='live'] {
        color: #0d6b3d;
        background: color-mix(in srgb, #34c759 28%, var(--glass-bg));
        border-color: color-mix(in srgb, #248a3d 55%, var(--glass-border));
      }
      .harbor-status[data-mode='demo'] {
        color: #8a4b00;
        background: color-mix(in srgb, #ff9f0a 30%, var(--glass-bg));
        border-color: color-mix(in srgb, #c93400 35%, var(--glass-border));
      }
      html[data-glass-preset='dark'] .harbor-status[data-mode='live'],
      html[data-glass-preset='auto'][data-bs-theme='dark'] .harbor-status[data-mode='live'] {
        color: #f4fff6;
        background: #0c341f;
        border-color: #6ee7a8;
      }
      html[data-glass-preset='dark'] .harbor-status[data-mode='demo'],
      html[data-glass-preset='auto'][data-bs-theme='dark'] .harbor-status[data-mode='demo'] {
        color: #ffd59a;
      }
      .harbor-sources { display: flex; flex-direction: column; gap: 0.55rem; }
      .harbor-sources-empty {
        align-items: flex-start;
        padding: 0.35rem 0.15rem 0.8rem;
      }
      .harbor-sources-mark {
        width: 2.4rem;
        height: 2.4rem;
        display: grid;
        place-items: center;
        border-radius: 0.9rem;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 80%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
      }
      .harbor-sources-title {
        margin: 0.15rem 0 0;
        font-weight: 600;
        color: var(--glass-body-color);
      }
      .harbor-sources-copy {
        margin: 0;
        color: var(--glass-body-color);
        opacity: 0.82;
      }
      .harbor-source {
        display: flex;
        flex-direction: row;
        align-items: flex-start;
        gap: 0.7rem;
        padding: 0.7rem 0.85rem;
        border-radius: 1rem;
        text-decoration: none;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 78%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight);
      }
      .harbor-source:hover { color: var(--glass-body-color); }
      .harbor-source-icon,
      .harbor-pill-icon {
        flex: 0 0 auto;
        width: 16px;
        height: 16px;
        margin-top: 0.15rem;
      }
      .harbor-source-icon svg,
      .harbor-pill-icon svg {
        display: block;
        width: 16px;
        height: 16px;
      }
      .harbor-source-body {
        display: flex;
        flex-direction: column;
        gap: 0.15rem;
        min-width: 0;
      }
      .harbor-source-title { font-weight: 600; }
      .harbor-pills {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
        margin-top: 0.65rem;
      }
      .harbor-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        min-height: 32px;
        padding: 0.15rem 0.7rem 0.15rem 0.35rem;
        border-radius: 999px;
        text-decoration: none;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 82%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight);
      }
      .harbor-pill:hover { color: var(--glass-body-color); }
      .harbor-pill-icon { margin-top: 0; }
      .harbor-pill-label { font-size: 0.82rem; font-weight: 600; }
      .harbor-source-note, .harbor-source-url {
        font-size: 0.82rem;
        opacity: 0.82;
        overflow-wrap: anywhere;
      }
    ")),
    tags$script(HTML("
      document.documentElement.classList.add('harbor-notes');
      (function () {
        function svgIcon(inner, bg) {
          var svg = \"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><rect width='16' height='16' rx='4' fill='\" + bg + \"'/>\" + inner + \"</svg>\";
          return 'data:image/svg+xml,' + encodeURIComponent(svg);
        }
        var ICONS = {
          docs: svgIcon(\"<path fill='#fff' d='M3.2 3.1h4.3c.9 0 1.6.7 1.6 1.6v7.5H5.1c-1.1 0-1.9.8-1.9 1.9V3.1z'/><path fill='#dbe4ff' d='M8.3 3.1h4.5v8.3H8.3c-.7 0-1.3-.6-1.3-1.3V4.4c0-.7.6-1.3 1.3-1.3z'/>\", '#3b5bdb'),
          github: svgIcon(\"<circle cx='5' cy='4.8' r='1.25' fill='#fff'/><circle cx='11' cy='4.8' r='1.25' fill='#fff'/><circle cx='8' cy='11.2' r='1.25' fill='#fff'/><path d='M5 6.1v2.1c0 1 .9 1.6 3 1.6h3V6.1' fill='none' stroke='#fff' stroke-width='1.15'/>\", '#24292f'),
          apple: svgIcon(\"<path fill='#fff' d='M8.1 2.8c.2 1 .9 1.6 1.8 1.7C9.7 5.8 8.8 6.8 8.1 6.8S6.5 5.8 6.3 4.5c.8-.1 1.6-.8 1.8-1.7z'/><path fill='#fff' d='M8 6.5c1.7 0 2.7 1.1 2.7 2.7 0 1.9-1.2 3.8-2.7 3.8S5.3 11.1 5.3 9.2C5.3 7.6 6.3 6.5 8 6.5z'/>\", '#1d1d1f'),
          posit: svgIcon(\"<circle cx='8' cy='8' r='3.15' fill='none' stroke='#fff' stroke-width='1.45'/><circle cx='8' cy='8' r='1.15' fill='#fff'/>\", '#447099')
        };
        function monogram(ch) {
          var letter = (ch || '?').charAt(0).toUpperCase();
          return svgIcon(\"<text x='8' y='11.2' text-anchor='middle' font-family='system-ui,sans-serif' font-size='9' font-weight='700' fill='#fff'>\" + letter + \"</text>\", '#5c6770');
        }
        function iconForHost(host) {
          host = String(host || '').toLowerCase();
          if (host.indexOf('apple.com') >= 0) return ICONS.apple;
          if (host.indexOf('posit') >= 0) return ICONS.posit;
          if (host === 'github.com' || host.slice(-11) === '.github.com') return ICONS.github;
          if (host.indexOf('github.io') >= 0 || host.indexOf('docs') >= 0 || host.indexOf('tidyverse.org') >= 0) return ICONS.docs;
          var bare = host.replace(/^www\\./, '');
          return monogram(bare.charAt(0) || '?');
        }
        function hostFromFavicon(url) {
          var raw = String(url || '');
          var match = raw.match(/ip3\\/([^/?#]+?)\\.ico/i);
          if (!match) return '';
          try { return decodeURIComponent(match[1]); } catch (e) { return match[1]; }
        }
        function rewriteFavicon(value) {
          var raw = String(value || '');
          if (!raw || raw.indexOf('data:') === 0) return raw;
          if (!/duckduckgo\\.com|gstatic\\.com\\/favicon|\\/favicons|favicon\\.ico/i.test(raw)) return raw;
          return iconForHost(hostFromFavicon(raw));
        }
        try {
          var desc = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
          if (desc && desc.set && desc.get) {
            Object.defineProperty(HTMLImageElement.prototype, 'src', {
              configurable: true,
              enumerable: desc.enumerable,
              get: function () { return desc.get.call(this); },
              set: function (value) { desc.set.call(this, rewriteFavicon(value)); }
            });
          }
          var origSet = Element.prototype.setAttribute;
          Element.prototype.setAttribute = function (name, value) {
            if (this instanceof HTMLImageElement && String(name).toLowerCase() === 'src') {
              value = rewriteFavicon(value);
            }
            return origSet.call(this, name, value);
          };
        } catch (e) {}
        function storageKey() {
          var path = (location.pathname || '/').replace(/\\/$/, '') || '/';
          return 'harbor-notes:' + path;
        }
        function asList(value) {
          if (!value) return [];
          if (Array.isArray(value)) return value;
          if (value.role || value.url || value.title) return [value];
          return [];
        }
        function readRaw() {
          try {
            var raw = localStorage.getItem(storageKey());
            if (!raw) return null;
            return JSON.parse(raw);
          } catch (e) { return null; }
        }
        var NOTICES = [
          'The live model is at its free-tier limit right now. Here is the local note instead.',
          'The live model could not answer just now. Here is the local note instead.',
          'This session has used its free messages. Here is the local note instead.',
          'That note is a bit long for this public demo. Try a shorter question about shinyglass, Shiny, or R.'
        ];
        var SOURCE_TITLES = [
          'shinyglass docs',
          'shinyglass README',
          'Apple HIG materials',
          'Adopting Liquid Glass',
          'Shiny docs',
          'shinychat'
        ];
        function splitNotice(text) {
          var body = String(text || '');
          for (var i = 0; i < NOTICES.length; i++) {
            if (body.indexOf(NOTICES[i]) === 0) {
              return { text: body.slice(NOTICES[i].length), notice: NOTICES[i] };
            }
          }
          return { text: body, notice: '' };
        }
        function stripLegacy(text) {
          var body = String(text || '');
          var cites = [];
          body.replace(/<shiny-aside\\b[^>]*>/gi, function (tag) {
            var url = (tag.match(/\\burl\\s*=\\s*\"([^\"]*)\"/i) || [])[1] || '';
            var title = (tag.match(/\\blabel\\s*=\\s*\"([^\"]*)\"/i) || [])[1] || '';
            if (url && url.indexOf('duckduckgo.com') < 0) cites.push({ title: title, url: url, note: '' });
            return tag;
          });
          body = body.replace(/<shiny-aside\\b[^>]*>[\\s\\S]*?<\\/shiny-aside>/gi, ' ');
          body = body.replace(/<img\\b[^>]*duckduckgo\\.com[^>]*>/gi, ' ');
          body = body.replace(/https?:\\/\\/icons\\.duckduckgo\\.com[^\\s\"'<>]*/gi, ' ');
          var guard = 0;
          while (/\\+\\d+\\s*$/.test(body) && guard < 12) {
            guard += 1;
            var ate = false;
            for (var t = 0; t < SOURCE_TITLES.length; t++) {
              var title = SOURCE_TITLES[t];
              var tail = new RegExp('\\\\s+' + title.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + '\\\\s+\\\\+\\\\d+\\\\s*$');
              if (tail.test(body)) {
                body = body.replace(tail, '');
                cites.push({ title: title, url: '', note: '' });
                ate = true;
                break;
              }
            }
            if (!ate) {
              body = body.replace(/\\s*\\+\\d+\\s*$/, '');
              var again = true;
              while (again) {
                again = false;
                for (var u = 0; u < SOURCE_TITLES.length; u++) {
                  var name = SOURCE_TITLES[u];
                  var end = new RegExp('\\\\s+' + name.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + '\\\\s*$');
                  if (end.test(body)) {
                    body = body.replace(end, '');
                    cites.push({ title: name, url: '', note: '' });
                    again = true;
                    break;
                  }
                }
              }
            }
          }
          return { text: body.replace(/\\s+/g, ' ').trim(), citations: cites };
        }
        function migrateStored(data) {
          data = data || {};
          var messages = asList(data.messages);
          var notice = data.notice || '';
          var globals = asList(data.citations).filter(function (item) {
            return item && item.url && String(item.url).indexOf('duckduckgo.com') < 0;
          });
          var cleaned = [];
          messages.forEach(function (msg) {
            if (!msg) return;
            var split = splitNotice(msg.text || '');
            if (split.notice) notice = split.notice;
            var legacy = stripLegacy(split.text);
            var text = legacy.text;
            if (!text) return;
            var cites = asList(msg.citations).concat(legacy.citations).filter(function (item) {
              return item && item.url && String(item.url).indexOf('duckduckgo.com') < 0;
            });
            cleaned.push({
              role: msg.role,
              text: text,
              thinking: msg.thinking || '',
              citations: cites
            });
          });
          for (var i = cleaned.length - 1; i >= 0; i--) {
            if (cleaned[i].role === 'assistant') {
              var seen = {};
              var merged = [];
              cleaned[i].citations.concat(globals).forEach(function (item) {
                if (!item || !item.url || seen[item.url]) return;
                seen[item.url] = true;
                merged.push({ title: item.title || item.url, url: item.url, note: item.note || '' });
              });
              cleaned[i].citations = merged;
              break;
            }
          }
          return { v: 3, messages: cleaned, citations: globals, notice: notice || '' };
        }
        function writeNotes(messages, citations, notice) {
          var prev = readRaw();
          var cites = citations;
          if (cites == null) cites = (prev && prev.citations) || [];
          var note = notice;
          if (note == null) note = (prev && prev.notice) || '';
          try {
            localStorage.setItem(storageKey(), JSON.stringify({
              v: 3,
              messages: messages || [],
              citations: cites || [],
              notice: note || ''
            }));
          } catch (e) {}
        }
        function plainText(node) {
          if (!node) return '';
          var clone = node.cloneNode(true);
          clone.querySelectorAll('.shiny-chat-thinking, .shiny-tool-card, .shiny-chat-tool-call-row, .shiny-chat-tool-group, shiny-aside, .shiny-aside-pill, .harbor-pills, .harbor-pill').forEach(function (el) {
            el.remove();
          });
          return (clone.innerText || '').replace(/\\s+/g, ' ').trim();
        }
        function pillCites(node) {
          var out = [];
          if (!node) return out;
          node.querySelectorAll('a.harbor-pill').forEach(function (a) {
            var label = a.querySelector('.harbor-pill-label');
            out.push({
              title: ((label && label.textContent) || '').replace(/\\s+/g, ' ').trim(),
              url: a.getAttribute('href') || '',
              note: ''
            });
          });
          return out;
        }
        function thoughtText(node) {
          var thought = node.querySelector('.shiny-chat-thinking');
          if (!thought) return '';
          var clone = thought.cloneNode(true);
          var header = clone.querySelector('.shiny-chat-thinking-header, button');
          if (header) header.remove();
          return (clone.innerText || '').replace(/\\s+/g, ' ').trim();
        }
        function snapshot() {
          var nodes = document.querySelectorAll('.shiny-chat-user-message, .shiny-chat-message');
          var out = [];
          nodes.forEach(function (node) {
            var pending = node.querySelector('.shiny-chat-message-content[data-pending]');
            if (pending) return;
            var role = node.classList.contains('shiny-chat-user-message') ? 'user' : 'assistant';
            var body = node.querySelector('.shiny-chat-message-content') || node;
            var text = plainText(body);
            if (!text) return;
            var item = { role: role, text: text.slice(0, 4000) };
            if (role === 'assistant') {
              item.thinking = thoughtText(body).slice(0, 2000);
              item.citations = pillCites(body);
            }
            out.push(item);
          });
          return out;
        }
        function sendRestore() {
          var migrated = migrateStored(readRaw() || {});
          var messages = asList(migrated.messages);
          var citations = asList(migrated.citations);
          if (messages.length || citations.length || migrated.notice) writeNotes(messages, citations, migrated.notice);
          Shiny.setInputValue('harbor_notes_restore', {
            role: messages.map(function (m) { return m.role; }),
            text: messages.map(function (m) { return m.text; }),
            thinking: messages.map(function (m) { return m.thinking || ''; }),
            msg_citations: messages.map(function (m) { return JSON.stringify(m.citations || []); }),
            notice: migrated.notice || '',
            cite_title: citations.map(function (c) { return c.title || ''; }),
            cite_url: citations.map(function (c) { return c.url || ''; }),
            cite_note: citations.map(function (c) { return c.note || ''; })
          }, { priority: 'event' });
        }
        function paintPills(html) {
          var nodes = document.querySelectorAll('.shiny-chat-message .shiny-chat-message-content');
          var last = nodes[nodes.length - 1];
          if (!last) return false;
          if (last.querySelector('.harbor-pills')) return true;
          last.insertAdjacentHTML('beforeend', html);
          return true;
        }
        function placeNotice() {
          var host = document.getElementById('harbor_notice_host');
          var main = document.querySelector('.shiny-chat-page-main');
          if (!host || !main) return;
          // The page grid is header plus one flexible row. A host between
          // those two steals the row and pins the sidebar to the bottom.
          if (host.parentElement !== main) main.insertBefore(host, main.firstChild);
        }
        function armNotice() {
          placeNotice();
          var note = document.querySelector('#harbor_notice_host .harbor-notice');
          if (!note || note.dataset.armed) return;
          note.dataset.armed = '1';
          var hide = function () { note.classList.add('is-hidden'); };
          var button = note.querySelector('.harbor-notice-dismiss');
          if (button) button.addEventListener('click', hide);
          window.setTimeout(hide, 8000);
        }
        function bind() {
          if (!window.Shiny || !Shiny.addCustomMessageHandler || !Shiny.setInputValue) return false;
          if (window.__harborNotesBound) return true;
          window.__harborNotesBound = true;
          var saveTimer = null;
          var haveServerNotes = false;
          var root = document.querySelector('shiny-chat-container') || document.body;
          Shiny.addCustomMessageHandler('harbor-notes-save', function (msg) {
            var cites = msg && Object.prototype.hasOwnProperty.call(msg, 'citations')
              ? asList(msg.citations)
              : null;
            var note = msg && Object.prototype.hasOwnProperty.call(msg, 'notice')
              ? (msg.notice || '')
              : null;
            haveServerNotes = true;
            writeNotes(asList(msg && msg.messages), cites, note);
          });
          Shiny.addCustomMessageHandler('harbor-notes-request', function (msg) {
            sendRestore();
          });
          Shiny.addCustomMessageHandler('harbor-notes-pills', function (msg) {
            var html = msg && msg.html;
            if (!html) return;
            var tries = 0;
            var tick = function () {
              if (paintPills(html) || tries > 20) return;
              tries += 1;
              window.setTimeout(tick, 50);
            };
            tick();
          });
          placeNotice();
          armNotice();
          if (window.MutationObserver) {
            var noticeHost = document.getElementById('harbor_notice_host');
            if (noticeHost) {
              new MutationObserver(function () { armNotice(); }).observe(noticeHost, {
                childList: true,
                subtree: true
              });
            }
          }
          if (window.MutationObserver && root) {
            var obs = new MutationObserver(function () {
              if (haveServerNotes) return;
              if (saveTimer) window.clearTimeout(saveTimer);
              saveTimer = window.setTimeout(function () {
                if (haveServerNotes) return;
                var messages = snapshot();
                if (messages.length) writeNotes(messages, null);
              }, 200);
            });
            obs.observe(root, {
              childList: true,
              subtree: true,
              characterData: true,
              attributes: true,
              attributeFilter: ['data-pending']
            });
          }
          return true;
        }
        function arm() {
          var $ = window.jQuery;
          if (!$ || !window.Shiny) return false;
          $(document).on('shiny:connected', bind);
          if (window.Shiny.shinyapp && Shiny.shinyapp.isConnected && Shiny.shinyapp.isConnected()) bind();
          return true;
        }
        if (!arm()) {
          document.addEventListener('DOMContentLoaded', function () {
            if (arm()) return;
            var tries = 0;
            var timer = window.setInterval(function () {
              tries += 1;
              if (arm() || tries > 40) window.clearInterval(timer);
            }, 50);
          });
        }
      })();
    "))
  ),
  tags$div(id = "harbor_notice_host", uiOutput("harbor_notice")),
  offcanvas(
    id = "sources_panel",
    title = "Sources",
    placement = "end",
    uiOutput("sources_body")
  ),
  page_chat(
  "Harbor notes",
  icon = tags$img(
    src = harbor_icon_src(),
    alt = "",
    class = "harbor-mark",
    width = "22",
    height = "22"
  ),
  # An empty drawer mounts hidden with no trigger. Thinking lives on the
  # "Thought for ..." disclosure, which only renders when thoughts exist.
  drawer = FALSE,
  id = "chat",
  theme = glass_theme(
    preset = glass_preset,
    scene = "dusk",
    intensity = 0.38,
    primary = "#007AFF",
    persist = TRUE
  ),
  allow_attachments = FALSE,
  placeholder = "Message",
  greeting = paste(
    "## Harbor notes",
    "Liquid Glass for Shiny, on this machine.",
    "",
    "* <span class=\"suggestion submit\" data-suggestion-submit=\"true\" title=\"Theme\">How does glass_theme work?</span>",
    "* <span class=\"suggestion submit\" data-suggestion-submit=\"true\" title=\"Chat\">Style a Shiny chat</span>",
    sep = "\n"
  ),
  footer = tags$div(
    class = "harbor-footer-row",
    uiOutput("harbor_status", inline = TRUE),
    tags$span("Notes stay on this machine.")
  ),
  sidebar = chat_sidebar(
    tags$p(class = "small text-secondary mb-2", "A harbor log on glass."),
    textInput("project", "Project", "Harbor", width = "100%"),
    history = TRUE,
    width = 260,
    open = "open"
  ),
  toolbar = toolbar(
    tagAppendAttributes(
      toolbar_input_button("open_sources", "Sources"),
      `data-bs-toggle` = "offcanvas",
      `data-bs-target` = "#sources_panel"
    )
  )
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

  note_log <- list()
  restoring <- FALSE
  restore_started <- FALSE
  fell_back <- FALSE
  citations <- reactiveVal(list())
  fallback_notice <- reactiveVal(NULL)
  reply_mode <- reactiveVal(if (live) "ready" else "demo")

  note_fallback <- function(notice, text = NULL) {
    fell_back <<- TRUE
    reply_mode("demo")
    if (!is.null(notice) && nzchar(notice)) fallback_notice(notice)
    if (!is.null(text)) add_citations(scripted_reply(text)$citations)
    invisible(notice)
  }

  publish_notes <- function() {
    session$sendCustomMessage("harbor-notes-save", list(
      messages = note_log,
      citations = citations(),
      notice = fallback_notice() %||% ""
    ))
  }

  # History only records turns that travel through chat_append(). The
  # scripted path writes messages directly, so publish the sidebar row
  # from the note log. The title is the first user message.
  publish_history <- function() {
    if (!length(note_log)) return(invisible(NULL))
    controller <- tryCatch(
      shinychat:::get_session_chat_bookmark_info(session, "chat.history-controller"),
      error = function(e) NULL
    )
    if (is.null(controller)) return(invisible(NULL))
    turns <- tryCatch(
      lapply(note_log, function(msg) {
        role <- if (identical(msg$role, "assistant")) "assistant" else "user"
        ellmer::Turn(role, msg$text)
      }),
      error = function(e) NULL
    )
    if (is.null(turns) || !length(turns)) return(invisible(NULL))
    if (!live) {
      try(client$set_turns(turns), silent = TRUE)
    }
    recs <- tryCatch(lapply(turns, ellmer::contents_record), error = function(e) NULL)
    if (is.null(recs)) return(invisible(NULL))
    tryCatch(controller$on_response(recs), error = function(e) NULL)
    invisible(NULL)
  }

  remember <- function(role, text, thinking = NULL, citations = NULL) {
    text <- trimws(paste(text %||% "", collapse = "\n"))
    if (!nzchar(text)) return(invisible(NULL))
    thinking <- trimws(paste(thinking %||% "", collapse = "\n"))
    if (!nzchar(thinking)) thinking <- NULL
    note_log[[length(note_log) + 1L]] <<- list(
      role = role,
      text = text,
      thinking = thinking,
      citations = unique_cites(citations)
    )
    if (length(note_log) > 40L) {
      note_log <<- note_log[(length(note_log) - 39L):length(note_log)]
    }
    if (!restoring) {
      publish_notes()
      publish_history()
    }
    invisible(NULL)
  }

  add_citations <- function(items) {
    current <- citations()
    for (item in items) {
      if (is.null(item) || is.null(item$url) || !nzchar(item$url)) next
      if (any(vapply(current, function(x) identical(x$url, item$url), logical(1)))) next
      current[[length(current) + 1L]] <- item
    }
    citations(current)
  }

  citation_from_part <- function(part) {
    if (!inherits(part, "ellmer::ContentCitation")) return(NULL)
    source <- tryCatch(part@source, error = function(e) NULL)
    if (is.null(source)) return(NULL)
    url <- tryCatch(source@url, error = function(e) NULL)
    title <- tryCatch(source@title, error = function(e) NULL)
    note <- tryCatch(part@grounded_span, error = function(e) "")
    if (is.null(url) || !nzchar(url)) return(NULL)
    if (is.null(title) || !nzchar(title)) title <- url
    list(title = title, url = url, note = note %||% "")
  }

  harvest_parts <- function(parts) {
    items <- list()
    if (is.null(parts)) return(items)
    for (part in parts) {
      item <- citation_from_part(part)
      if (!is.null(item)) items[[length(items) + 1L]] <- item
    }
    items
  }

  harvest_turns <- function() {
    turns <- tryCatch(client$get_turns(), error = function(e) NULL)
    items <- list()
    if (is.null(turns)) return(items)
    for (turn in turns) {
      contents <- tryCatch(turn@contents, error = function(e) NULL)
      if (is.null(contents)) next
      items <- c(items, harvest_parts(contents))
    }
    items
  }

  part_text <- function(part) {
    if (is.character(part)) {
      if (inherits(part, "shinychat_block") || inherits(part, "shinychat_thinking")) {
        return("")
      }
      value <- paste(part, collapse = "\n")
      if (grepl("<", value, fixed = TRUE)) return("")
      return(value)
    }
    if (inherits(part, "ellmer::ContentText")) {
      value <- tryCatch(part@text, error = function(e) NULL)
      if (is.null(value)) return("")
      return(paste(value, collapse = "\n"))
    }
    ""
  }

  part_thinking <- function(part) {
    if (inherits(part, "ellmer::ContentThinking")) {
      value <- tryCatch(part@thinking, error = function(e) NULL)
      if (is.null(value)) return("")
      return(paste(value, collapse = "\n"))
    }
    if (inherits(part, "shinychat_thinking")) {
      return(paste(as.character(part), collapse = "\n"))
    }
    ""
  }

  show_reply_pills <- function(items) {
    pills <- source_pills_html(items)
    if (is.null(pills)) return(invisible(NULL))
    session$sendCustomMessage("harbor-notes-pills", list(html = as.character(pills)))
    invisible(pills)
  }

  finish_live <- function(parts, text = NULL) {
    if (!is.list(parts)) parts <- list()
    found <- unique_cites(c(harvest_parts(parts), harvest_turns()))
    answer <- paste(vapply(parts, part_text, character(1)), collapse = "")
    if (!length(found)) found <- curated_citations(paste(text %||% "", answer))
    add_citations(found)
    show_reply_pills(found)
    thinking <- trimws(paste(vapply(parts, part_thinking, character(1)), collapse = "\n"))
    if (!nzchar(thinking)) thinking <- NULL
    remember("assistant", answer, thinking, found)
    invisible(parts)
  }

  pipe_live <- function(stream, text) {
    fell_back <<- FALSE
    result <- chat_append("chat", stream)
    promises::then(
      result,
      onFulfilled = function(value) {
        if (!fell_back) {
          reply_mode("live")
          fallback_notice(NULL)
        }
        finish_live(value, text)
      },
      onRejected = function(err) NULL
    )
  }

  send_mock <- function(text, notice = NULL) {
    reply <- scripted_reply(text)
    if (!is.null(notice) && nzchar(notice)) {
      fallback_notice(notice)
      reply_mode("demo")
    } else if (!live) {
      fallback_notice(NULL)
    }
    add_citations(reply$citations)
    stream_pieces("chat", reply_pieces(reply, NULL), session, pace)
    remember("assistant", reply$body, reply$thinking, reply$citations)
  }

  # Recreate the Gemini client so thinking params match the model.
  # The local stand-in has no key; set_model is enough there.
  switch_live_client <- function(model, params) {
    if (is.null(built$key)) {
      try(client$set_model(model), silent = TRUE)
      return(TRUE)
    }
    turns <- tryCatch(client$get_turns(), error = function(e) NULL)
    next_client <- tryCatch(
      new_gemini_client(built$key, model, params),
      error = function(e) NULL
    )
    if (is.null(next_client)) return(FALSE)
    if (!is.null(turns) && length(turns)) {
      try(next_client$set_turns(turns), silent = TRUE)
    }
    client <<- next_client
    TRUE
  }

  start_live <- function(text) {
    models <- built$models
    if (!length(models)) models <- gemini_model_chain()
    index <- 1L
    plain <- FALSE
    last_err <- NULL

    fail <- function(err) {
      reply_mode("demo")
      send_mock(text, api_notice(err))
      invisible(NULL)
    }

    if (harbor_fallback_requested(session$clientData$url_search)) {
      err <- simpleError("forced fallback")
      class(err) <- c("httr2_http_429", "error", "condition")
      return(fail(err))
    }

    succeed <- function(stream) {
      pipe_live(guarded_stream(stream, text, on_fallback = function(notice) {
        note_fallback(notice, text)
      }), text)
    }

    attempt <- function() {
      if (index > length(models)) return(fail(last_err))
      model <- models[[index]]
      params <- if (plain) NULL else gemini_params(model)
      if (!switch_live_client(model, params)) {
        index <<- index + 1L
        plain <<- FALSE
        return(attempt())
      }
      turns_before <- tryCatch(client$get_turns(), error = function(e) NULL)
      started <- tryCatch(
        client$stream_async(text, stream = "content"),
        error = function(e) e
      )
      handle_started(started, turns_before)
    }

    rewind_turns <- function(turns_before) {
      if (is.null(turns_before)) return(invisible(NULL))
      try(client$set_turns(turns_before), silent = TRUE)
      invisible(NULL)
    }

    handle_started <- function(started, turns_before) {
      if (inherits(started, "error")) {
        rewind_turns(turns_before)
        return(advance(started))
      }
      if (promises::is.promise(started)) {
        promises::then(
          started,
          onFulfilled = function(inner) succeed(inner),
          onRejected = function(err) {
            rewind_turns(turns_before)
            advance(err)
          }
        )
        return(invisible(NULL))
      }
      succeed(started)
    }

    advance <- function(err) {
      last_err <<- err
      decision <- chain_decision(err, plain)
      if (identical(decision, "retry_plain")) {
        plain <<- TRUE
        return(attempt())
      }
      if (identical(decision, "next")) {
        index <<- index + 1L
        plain <<- FALSE
        return(attempt())
      }
      fail(err)
    }

    attempt()
    invisible(NULL)
  }

  answer <- function(text) {
    raw <- user_text(text)
    decision <- gate_turn(raw, harbor_turn_budget(used, input$harbor_visitor_turns), live)
    used <<- decision$used
    if (identical(decision$action, "live")) {
      session$sendCustomMessage("harbor-turns-save", list(used = decision$used))
    }
    if (identical(decision$action, "ignore")) return(invisible(NULL))
    remember("user", raw)
    if (identical(decision$action, "live")) {
      start_live(decision$text)
    } else {
      send_mock(decision$text, decision$notice)
    }
    invisible(NULL)
  }

  output$harbor_status <- renderUI({
    harbor_status_ui(reply_mode())
  })

  output$harbor_notice <- renderUI({
    msg <- fallback_notice()
    if (is.null(msg) || !nzchar(msg)) return(NULL)
    tags$div(
      class = "harbor-notice",
      role = "status",
      tags$p(class = "harbor-notice-copy", msg),
      tags$button(
        type = "button",
        class = "harbor-notice-dismiss",
        `aria-label` = "Dismiss notice",
        "\u00d7"
      )
    )
  })

  restore_message <- function(msg) {
    thinking <- msg$thinking %||% ""
    pills <- if (identical(msg$role, "assistant")) source_pills_html(msg$citations) else NULL
    has_think <- identical(msg$role, "assistant") && nzchar(thinking)
    if (!has_think && is.null(pills)) {
      chat_append_message(
        "chat",
        list(role = msg$role, content = msg$text),
        chunk = FALSE,
        session = session
      )
      return(invisible(NULL))
    }
    if (has_think) {
      chat_append_message(
        "chat",
        list(role = "assistant", content = thinking_block(thinking)),
        chunk = "start",
        session = session
      )
    } else {
      chat_append_message(
        "chat",
        list(role = "assistant", content = msg$text),
        chunk = "start",
        session = session
      )
    }
    if (has_think && !is.null(pills)) {
      chat_append_message(
        "chat",
        list(role = "assistant", content = msg$text),
        chunk = TRUE,
        session = session
      )
      chat_append_message(
        "chat",
        list(role = "assistant", content = pills),
        chunk = "end",
        session = session
      )
    } else if (has_think) {
      chat_append_message(
        "chat",
        list(role = "assistant", content = msg$text),
        chunk = "end",
        session = session
      )
    } else {
      chat_append_message(
        "chat",
        list(role = "assistant", content = pills),
        chunk = "end",
        session = session
      )
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
    session$sendCustomMessage("harbor-notes-request", list())
  }, once = TRUE)

  observeEvent(input$chat_user_input, {
    answer(input$chat_user_input)
  }, ignoreInit = TRUE)

  observeEvent(input$chat_slash_command, {
    if (live) {
      answer("Save a short harbor note about shinyglass.")
    } else {
      remember("assistant", "Saved the note locally. It stays on this machine.")
      stream_pieces(
        "chat",
        list("Saved the note locally. It stays on this machine."),
        session,
        pace
      )
    }
  }, ignoreInit = TRUE)

  observeEvent(input$chat_history_new, {
    note_log <<- list()
    citations(list())
    fallback_notice(NULL)
    reply_mode(if (live) "ready" else "demo")
    publish_notes()
  }, ignoreInit = TRUE)

  observeEvent(input$harbor_notes_restore, {
    if (restore_started || length(note_log)) return()
    payload <- input$harbor_notes_restore
    stored <- migrate_stored_transcript(payload)
    msgs <- Filter(function(msg) {
      msg$role %in% c("user", "assistant") && nzchar(msg$text)
    }, stored$messages)
    restored_cites <- stored$citations
    restored_note <- stored$notice %||% ""
    if (!length(msgs) && !length(restored_cites) && !nzchar(restored_note)) return()
    restore_started <<- TRUE
    if (nzchar(restored_note)) {
      fallback_notice(restored_note)
      reply_mode("demo")
    } else if (live && length(msgs)) {
      reply_mode("live")
    }
    if (length(restored_cites)) add_citations(restored_cites)
    if (!length(msgs)) {
      publish_notes()
      return()
    }
    restoring <<- TRUE
    turns <- tryCatch(
      lapply(msgs, function(msg) ellmer::Turn(msg$role, msg$text)),
      error = function(e) NULL
    )
    if (!is.null(turns) && length(turns)) {
      try(client$set_turns(turns), silent = TRUE)
    }
    session$onFlushed(function() {
      on.exit(restoring <<- FALSE, add = TRUE)
      for (msg in msgs) {
        restore_message(msg)
        remember(msg$role, msg$text, msg$thinking, msg$citations)
      }
      publish_history()
    }, once = TRUE)
  }, ignoreInit = TRUE)

  output$sources_body <- renderUI({
    sources_panel(citations())
  })

  sources_panel <- function(items) {
    if (!length(items)) {
      return(div(
        class = "harbor-sources harbor-sources-empty",
        div(class = "harbor-sources-mark", "\u25c7"),
        tags$p(class = "harbor-sources-title", "No sources yet"),
        tags$p(
          class = "harbor-sources-copy",
          "Ask a question and citations from the reply will collect here."
        )
      ))
    }
    div(
      class = "harbor-sources",
      lapply(items, function(item) {
        tags$a(
          class = "harbor-source",
          href = item$url,
          target = "_blank",
          rel = "noopener noreferrer",
          source_icon_span(item$url, "harbor-source-icon"),
          tags$span(
            class = "harbor-source-body",
            tags$span(class = "harbor-source-title", item$title),
            if (nzchar(item$note %||% "")) tags$span(class = "harbor-source-note", item$note),
            tags$span(class = "harbor-source-url", item$url)
          )
        )
      })
    )
  }

}

ui <- function(request) {
  phone_preview(harbor_page, app = "chat", request = request)
}

app <- shinyApp(ui, server)
app
