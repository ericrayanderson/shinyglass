# Rewrite docs/llms.txt and write docs/llms-full.txt after pkgdown::build_site().
# pkgdown >= 2.2 already writes a .md copy of every HTML page and a default
# llms.txt (the home, reference, and article indexes pasted together).
# This step replaces that index with a short map and adds the full dump.
#
# Run from the package root:
#   Rscript inst/scripts/build-llms.R

docs <- "docs"
if (!dir.exists(docs)) {
  stop("docs/ is missing. Run pkgdown::build_site() first.", call. = FALSE)
}

# pkgdown renders every root *.md except a short built-in deny list.
# AGENTS.md stays at the repo root for AI coding assistants.
# It is not package docs, so drop the page pkgdown just wrote.
agent_pages <- "AGENTS"
unlink(file.path(docs, paste0(agent_pages, ".html")))
unlink(file.path(docs, paste0(agent_pages, ".md")))

sitemap <- file.path(docs, "sitemap.xml")
if (file.exists(sitemap)) {
  lines <- readLines(sitemap, warn = FALSE, encoding = "UTF-8")
  drop <- grepl("AGENTS\\.html", lines, perl = TRUE)
  if (any(drop)) writeLines(lines[!drop], sitemap, useBytes = TRUE)
}

search <- file.path(docs, "search.json")
if (file.exists(search)) {
  # Keep the original object text. Rewriting with jsonlite turns JSON null
  # into {} and would change every other search hit.
  raw <- paste(readLines(search, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  chars <- strsplit(raw, "", fixed = TRUE)[[1]]
  n <- length(chars)
  objects <- character()
  i <- 1L
  while (i <= n && chars[[i]] != "[") i <- i + 1L
  i <- i + 1L
  while (i <= n) {
    while (i <= n && chars[[i]] %in% c(" ", "\n", "\r", "\t", ",")) i <- i + 1L
    if (i > n || chars[[i]] == "]") break
    if (chars[[i]] != "{") {
      stop("search.json is not an array of objects.", call. = FALSE)
    }
    start <- i
    depth <- 0L
    in_str <- FALSE
    escape <- FALSE
    while (i <= n) {
      ch <- chars[[i]]
      if (in_str) {
        if (escape) {
          escape <- FALSE
        } else if (ch == "\\") {
          escape <- TRUE
        } else if (ch == "\"") {
          in_str <- FALSE
        }
      } else if (ch == "\"") {
        in_str <- TRUE
      } else if (ch == "{") {
        depth <- depth + 1L
      } else if (ch == "}") {
        depth <- depth - 1L
        if (depth == 0L) {
          i <- i + 1L
          break
        }
      }
      i <- i + 1L
    }
    objects <- c(objects, paste(chars[start:(i - 1L)], collapse = ""))
  }
  keep <- !grepl("AGENTS\\.html", objects)
  if (any(!keep)) {
    writeLines(
      paste0("[", paste(objects[keep], collapse = ","), "]"),
      search,
      useBytes = TRUE
    )
  }
}

if ("pkgdown" %in% loadedNamespaces() || requireNamespace("pkgdown", quietly = TRUE)) {
  has_llm <- exists("build_llm_docs", where = asNamespace("pkgdown"), inherits = FALSE)
  theme_md <- file.path(docs, "reference", "glass_theme.md")
  if (isTRUE(has_llm) && !file.exists(theme_md)) {
    pkgdown::build_llm_docs(".")
  }
}

theme_md <- file.path(docs, "reference", "glass_theme.md")
if (!file.exists(theme_md)) {
  stop(
    "docs/reference/glass_theme.md is missing. Install pkgdown >= 2.2 so build_llm_docs() runs.",
    call. = FALSE
  )
}

site <- "https://ericrayanderson.github.io/shinyglass/"

link_line <- function(path, label, blurb) {
  sprintf("- [%s](%s%s): %s", label, site, path, blurb)
}

key_functions <- c(
  link_line("reference/glass_theme.md", "glass_theme()", "bslib theme. Intensity is 0 to 1, default 0.5. preset is light, dark, or auto."),
  link_line("reference/glass_page.md", "glass_page()", "fluidPage wrapper with the toggle, intensity slider, and accent wells. Persistence defaults to TRUE."),
  link_line("reference/update_glass_theme.md", "update_glass_theme()", "Change preset, intensity, scene, and other options in a running app."),
  link_line("reference/observe_glass.md", "observe_glass()", "Register the default glass_page controls on the server."),
  link_line("reference/glass_intensity_slider.md", "glass_intensity_slider()", "Slider from Ultra Clear (0) to Tinted (1)."),
  link_line("reference/glass_theme_toggle.md", "glass_theme_toggle()", "Light, Dark, and Auto buttons."),
  link_line("reference/glass_flatten.md", "glass_flatten()", "Turn off blur for screenshots, PDF, and print."),
  link_line("reference/theme_glass.md", "theme_glass()", "ggplot2 theme using the resolved glass ink."),
  link_line("reference/plotly_glass.md", "plotly_glass()", "plotly layout using the resolved glass ink."),
  link_line("reference/gt_theme_glass.md", "gt_theme_glass()", "gt table chrome that matches the glass pack."),
  link_line("reference/dt_options_glass.md", "dt_options_glass()", "Optional DT options for tables on glass cards."),
  link_line("reference/glass_page_react.md", "glass_page_react()", "shinyreact page. Pass theme by name so the CSS is not dropped."),
  link_line("reference/glass_css_tokens.md", "glass_css_tokens()", "Catalog of public --glass-* custom properties.")
)

articles <- c(
  link_line("articles/theming.md", "Theming and light/dark", "Presets, scenes, intensity, and live updates."),
  link_line("articles/migrating.md", "Migrating to 0.5.0", "Breaking visual defaults and the deprecated material argument."),
  link_line("articles/compatibility.md", "Ecosystem compatibility", "Widgets and page functions that keep working."),
  link_line("articles/shinyreact.md", "shinyreact", "Named theme, GlassPage, and useGlassTheme."),
  link_line("articles/shinychat.md", "shinychat", "page_chat() and offcanvas on glass."),
  link_line("articles/playground.md", "Try it", "A small app you can run locally."),
  link_line("articles/ai-assistants.md", "AI coding assistants", "Canonical app and copy-paste prompts.")
)

missing <- character()
for (item in c(key_functions, articles)) {
  path <- sub(".*\\]\\(", "", item)
  path <- sub("\\):.*", "", path)
  path <- sub(site, "", path, fixed = TRUE)
  if (!file.exists(file.path(docs, path))) missing <- c(missing, path)
}
if (length(missing)) {
  stop(
    "Missing markdown pages: ",
    paste(unique(missing), collapse = ", "),
    call. = FALSE
  )
}

index <- c(
  "# shinyglass",
  "",
  "> Liquid Glass themes for Shiny, matching Apple iOS 27 as far as a browser can. glass_theme() and glass_page() add translucent surfaces, backdrop blur, light/dark/auto switching, and an intensity slider from 0 (Ultra Clear) to 1 (Tinted). The default intensity is 0.5. Accessibility settings (reduced transparency, increased contrast, forced colors, reduced motion) override the glass.",
  "",
  "## Install",
  "",
  "```r",
  "install.packages(\"shinyglass\")",
  "# remotes::install_github(\"ericrayanderson/shinyglass\")",
  "```",
  "",
  "## Minimal example",
  "",
  "```r",
  "library(shiny)",
  "library(bslib)",
  "library(shinyglass)",
  "",
  "ui <- page_sidebar(",
  "  title = \"Existing app\",",
  "  theme = glass_theme(preset = \"auto\", intensity = 0.5),",
  "  sidebar = sidebar(glass_theme_toggle(), glass_intensity_slider()),",
  "  \"Main column\"",
  ")",
  "",
  "server <- function(input, output, session) {",
  "  observe_glass(input, session)",
  "}",
  "",
  "shinyApp(ui, server)",
  "```",
  "",
  "material = \"clear\" is deprecated. Pass intensity instead. glass_page() is the one-call page and turns persistence on.",
  "",
  "## Key functions",
  "",
  key_functions,
  "",
  "## Articles",
  "",
  articles,
  ""
)

writeLines(index, file.path(docs, "llms.txt"), useBytes = TRUE)

md_files <- list.files(docs, pattern = "[.]md$", recursive = TRUE, full.names = TRUE)
md_files <- md_files[!grepl("(^|/)llms(-full)?[.]txt$", md_files)]
md_files <- md_files[basename(md_files) != "AGENTS.md"]
# Stable order: home, reference, articles, news, then the rest.
rank <- function(path) {
  rel <- sub(paste0("^", docs, "/"), "", path)
  if (identical(rel, "index.md")) return(0)
  if (startsWith(rel, "reference/")) return(1)
  if (startsWith(rel, "articles/")) return(2)
  if (startsWith(rel, "news/")) return(3)
  4
}
md_files <- md_files[order(vapply(md_files, rank, numeric(1)), md_files)]

full <- c(
  "# shinyglass (full)",
  "",
  "Concatenation of the Markdown copy of each pkgdown page.",
  ""
)
for (path in md_files) {
  rel <- sub(paste0("^", docs, "/"), "", path)
  full <- c(full, "", paste0("<!-- ", rel, " -->"), "", readLines(path, warn = FALSE, encoding = "UTF-8"))
}
writeLines(full, file.path(docs, "llms-full.txt"), useBytes = TRUE)

message(
  "Wrote ", file.path(docs, "llms.txt"),
  " (", length(index), " lines) and ",
  file.path(docs, "llms-full.txt"),
  " from ", length(md_files), " pages."
)
