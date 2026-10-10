# Harbor notes: the shinyglass chat demo.
# Local script by default. GEMINI_API_KEY or GOOGLE_API_KEY uses Gemini Flash
# with web search and thinking. A live reply with no grounding citations
# gets topic-matched docs instead.
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

aside_html <- function(item) {
  sprintf(
    "<shiny-aside label=\"%s\" url=\"%s\">%s</shiny-aside>",
    item$title,
    item$url,
    item$note
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

reply_pieces <- function(reply, notice = NULL) {
  pieces <- c(
    list(thinking_block(reply$thinking)),
    chunk_words(reply$body),
    lapply(reply$citations, aside_html)
  )
  if (!is.null(reply$tool)) pieces <- c(pieces, list(reply$tool))
  if (!is.null(notice) && nzchar(notice)) pieces <- c(list(notice), pieces)
  pieces
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

gemini_model <- function() {
  model <- Sys.getenv("SHINYGLASS_CHAT_MODEL", "gemini-3.7-flash")
  if (!nzchar(model)) "gemini-3.7-flash" else model
}

harbor_system_prompt <- function() {
  paste(
    "You help with shinyglass, Shiny, and R, and with ordinary conversation.",
    "Answer clearly in a few sentences.",
    "When a fact should be checked, search the web and cite the page.",
    "Decline only a clearly unrelated or abusive request, in one short sentence, without role-play."
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
        fallback <<- mock_pieces(text, notice)
        next
      }
      if (promises::is.promise(piece)) {
        yield(promises::then(
          piece,
          onFulfilled = function(value) value,
          onRejected = function(err) {
            notice <- api_notice(err)
            if (is.function(on_fallback)) on_fallback(notice)
            fallback <<- mock_pieces(text, NULL)
            notice
          }
        ))
      } else {
        yield(piece)
      }
    }
  })
}

# Gemini 3 takes a thinking level. Older Gemini models take a token budget.
# Either one makes ellmer send includeThoughts, so a live reply can show
# "Thought for ..." instead of an empty hidden drawer.
gemini_params <- function(model = gemini_model()) {
  if (grepl("^gemini-3", model)) {
    ellmer::params(reasoning_effort = "low")
  } else {
    ellmer::params(reasoning_tokens = 1024L)
  }
}

make_client <- function() {
  if (identical(Sys.getenv("SHINYGLASS_CHAT_MOCK_LIVE"), "1")) {
    return(list(client = make_mock_live_chat(), live = TRUE))
  }
  key <- gemini_key()
  if (is.null(key)) {
    return(list(client = make_echo_chat(), live = FALSE))
  }
  client <- tryCatch(
    ellmer::chat_google_gemini(
      system_prompt = harbor_system_prompt(),
      model = gemini_model(),
      api_key = key,
      params = gemini_params()
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
  tryCatch(
    client$register_tool(ellmer::google_tool_web_search()),
    error = function(e) {
      warning(
        "Web search could not be enabled. Live replies will use curated citations.",
        call. = FALSE
      )
    }
  )
  list(client = client, live = TRUE)
}

# Inline droplet. A data URI still loads when the app is hosted on a
# shinyapps.io subpath and the browser never asks the origin for /favicon.ico.
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

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark", "auto")
)

ui <- tagList(
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml", href = harbor_icon_src()),
    tags$link(rel = "alternate icon", type = "image/x-icon", href = "favicon.ico"),
    tags$style(HTML("
      .harbor-mark { display: block; width: 22px; height: 22px; }
      #harbor_notice_host {
        position: fixed;
        z-index: 30;
        top: 4.25rem;
        left: 50%;
        transform: translateX(-50%);
        width: min(36rem, calc(100% - 1.5rem));
        pointer-events: none;
      }
      .harbor-notice {
        pointer-events: auto;
        margin: 0;
        padding: 0.7rem 0.95rem;
        border-radius: 1rem;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 88%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight), 0 12px 32px var(--glass-shadow);
        backdrop-filter: blur(18px) saturate(var(--glass-saturate));
        -webkit-backdrop-filter: blur(18px) saturate(var(--glass-saturate));
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
        flex-direction: column;
        gap: 0.15rem;
        padding: 0.7rem 0.85rem;
        border-radius: 1rem;
        text-decoration: none;
        color: var(--glass-body-color);
        background: color-mix(in srgb, var(--glass-bg) 78%, var(--glass-body-bg));
        border: 0.5px solid var(--glass-border);
        box-shadow: inset 0 1px 0 var(--glass-highlight);
      }
      .harbor-source:hover { color: var(--glass-body-color); }
      .harbor-source-title { font-weight: 600; }
      .harbor-source-note, .harbor-source-url {
        font-size: 0.82rem;
        opacity: 0.82;
        overflow-wrap: anywhere;
      }
    ")),
    tags$script(HTML("
      (function () {
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
        function writeNotes(messages, citations) {
          var prev = readRaw();
          var cites = citations;
          if (!cites) cites = (prev && prev.citations) || [];
          try {
            localStorage.setItem(storageKey(), JSON.stringify({
              v: 1,
              messages: messages || [],
              citations: cites || []
            }));
          } catch (e) {}
        }
        function snapshot() {
          var nodes = document.querySelectorAll('.shiny-chat-user-message, .shiny-chat-message');
          var out = [];
          nodes.forEach(function (node) {
            var pending = node.querySelector('.shiny-chat-message-content[data-pending]');
            if (pending) return;
            var role = node.classList.contains('shiny-chat-user-message') ? 'user' : 'assistant';
            var body = node.querySelector('.shiny-chat-message-content') || node;
            var text = (body.innerText || '').replace(/\\s+/g, ' ').trim();
            if (!text) return;
            out.push({ role: role, text: text.slice(0, 4000) });
          });
          return out;
        }
        function sendRestore() {
          var data = readRaw();
          var messages = asList(data && data.messages);
          var citations = asList(data && data.citations);
          Shiny.setInputValue('harbor_notes_restore', {
            role: messages.map(function (m) { return m.role; }),
            text: messages.map(function (m) { return m.text; }),
            cite_title: citations.map(function (c) { return c.title || ''; }),
            cite_url: citations.map(function (c) { return c.url || ''; }),
            cite_note: citations.map(function (c) { return c.note || ''; })
          }, { priority: 'event' });
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
            haveServerNotes = true;
            writeNotes(asList(msg && msg.messages), cites);
          });
          Shiny.addCustomMessageHandler('harbor-notes-request', function (msg) {
            sendRestore();
          });
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

  note_fallback <- function(notice, text = NULL) {
    if (!is.null(notice) && nzchar(notice)) fallback_notice(notice)
    if (!is.null(text)) add_citations(scripted_reply(text)$citations)
    invisible(notice)
  }
  note_log <- list()
  restoring <- FALSE
  restore_started <- FALSE
  citations <- reactiveVal(list())
  fallback_notice <- reactiveVal(NULL)

  publish_notes <- function() {
    session$sendCustomMessage("harbor-notes-save", list(
      messages = note_log,
      citations = citations()
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

  remember <- function(role, text) {
    text <- paste(text %||% "", collapse = "\n")
    text <- trimws(text)
    if (!nzchar(text)) return(invisible(NULL))
    note_log[[length(note_log) + 1L]] <<- list(role = role, text = text)
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
      return(paste(part, collapse = "\n"))
    }
    if (inherits(part, "ellmer::ContentText")) {
      value <- tryCatch(part@text, error = function(e) NULL)
      if (is.null(value)) return("")
      return(paste(value, collapse = "\n"))
    }
    if (inherits(part, "ellmer::ContentThinking")) {
      value <- tryCatch(part@thinking, error = function(e) NULL)
      if (is.null(value) || !nzchar(value)) return("")
      return("")
    }
    ""
  }

  remember_parts <- function(parts) {
    text <- paste(vapply(parts, part_text, character(1)), collapse = "")
    remember("assistant", text)
  }

  finish_live <- function(parts, text = NULL) {
    if (!is.list(parts)) parts <- list()
    found <- c(harvest_parts(parts), harvest_turns())
    add_citations(found)
    if (!length(found)) {
      answer <- paste(vapply(parts, part_text, character(1)), collapse = "")
      add_citations(curated_citations(paste(text %||% "", answer)))
    }
    remember_parts(parts)
    invisible(parts)
  }

  pipe_live <- function(stream, text) {
    result <- chat_append("chat", stream)
    promises::then(
      result,
      onFulfilled = function(value) finish_live(value, text),
      onRejected = function(err) NULL
    )
  }

  send_mock <- function(text, notice = NULL) {
    reply <- scripted_reply(text)
    if (!is.null(notice) && nzchar(notice)) fallback_notice(notice)
    add_citations(reply$citations)
    stream_pieces("chat", reply_pieces(reply, notice), session, pace)
    remember("assistant", reply$body)
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
          pipe_live(guarded_stream(inner, text, on_fallback = function(notice) {
            note_fallback(notice, text)
          }), text)
        },
        onRejected = function(err) send_mock(text, api_notice(err))
      )
      return(invisible(NULL))
    }
    pipe_live(guarded_stream(started, text, on_fallback = function(notice) {
      note_fallback(notice, text)
    }), text)
    invisible(NULL)
  }

  answer <- function(text) {
    raw <- user_text(text)
    decision <- gate_turn(raw, used, live)
    used <<- decision$used
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
    if (live) {
      tags$span(class = "harbor-status", `data-mode` = "live", "Live (Gemini)")
    } else {
      tags$span(class = "harbor-status", `data-mode` = "demo", "Demo replies")
    }
  })

  output$harbor_notice <- renderUI({
    msg <- fallback_notice()
    if (is.null(msg) || !nzchar(msg)) return(NULL)
    tags$div(class = "harbor-notice", role = "status", msg)
  })

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
    lapply(seq_len(n), function(i) list(role = roles[[i]], text = texts[[i]]))
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
    publish_notes()
  }, ignoreInit = TRUE)

  observeEvent(input$harbor_notes_restore, {
    if (restore_started || length(note_log)) return()
    payload <- input$harbor_notes_restore
    msgs <- normalize_restore(payload)
    msgs <- Filter(function(msg) {
      msg$role %in% c("user", "assistant") && nzchar(msg$text)
    }, msgs)
    cite_titles <- as.character(unlist(payload$cite_title, use.names = FALSE))
    cite_urls <- as.character(unlist(payload$cite_url, use.names = FALSE))
    cite_notes <- as.character(unlist(payload$cite_note, use.names = FALSE))
    n_cites <- max(length(cite_titles), length(cite_urls), length(cite_notes))
    restored_cites <- if (n_cites) {
      lapply(seq_len(n_cites), function(i) {
        list(
          title = if (i <= length(cite_titles)) cite_titles[[i]] else "",
          url = if (i <= length(cite_urls)) cite_urls[[i]] else "",
          note = if (i <= length(cite_notes)) cite_notes[[i]] else ""
        )
      })
    } else {
      list()
    }
    if (!length(msgs) && !length(restored_cites)) return()
    restore_started <<- TRUE
    if (length(restored_cites)) add_citations(restored_cites)
    if (!length(msgs)) return()
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
        chat_append_message(
          "chat",
          list(role = msg$role, content = msg$text),
          chunk = FALSE,
          session = session
        )
        remember(msg$role, msg$text)
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
          tags$span(class = "harbor-source-title", item$title),
          if (nzchar(item$note %||% "")) tags$span(class = "harbor-source-note", item$note),
          tags$span(class = "harbor-source-url", item$url)
        )
      })
    )
  }

}

app <- shinyApp(ui, server)
app
