#' Ink and grid colors for the current glass appearance
#'
#' @param preset `"light"` or `"dark"`. When `NULL`, uses
#'   [glass_resolved_preset()] on `input`.
#' @param input Optional Shiny `input` (used when `preset` is `NULL`).
#' @param surface `"clear"` (transparent paper, default) or `"opaque"`
#'   (~94% panel fill). Pair `"opaque"` with [glass_theme()]
#'   `plot_surface = "opaque"` when the host CSS is not enough (for example
#'   exported ggplot images).
#'
#' @return A list with `preset`, `ink`, `grid`, `fill`, `paper`, and `surface`.
#' @export
glass_plot_colors <- function(preset = NULL, input = NULL,
                             surface = c("clear", "opaque")) {
  if (is.null(preset)) {
    preset <- glass_resolved_preset(input)
  }
  preset <- match.arg(preset, c("light", "dark"))
  surface <- match.arg(surface)
  if (identical(preset, "dark")) {
    pal <- list(
      preset = "dark",
      ink = "#f5f5f7",
      grid = "rgba(245,245,247,0.12)",
      fill = "#0A84FF",
      paper = "rgba(0,0,0,0)",
      surface = surface
    )
  } else {
    pal <- list(
      preset = "light",
      ink = "#1d1d1f",
      grid = "rgba(29,29,31,0.10)",
      fill = "#007AFF",
      paper = "rgba(0,0,0,0)",
      surface = surface
    )
  }
  if (identical(surface, "opaque")) {
    # ggplot2 accepts #RRGGBBAA; plotly/gt accept CSS rgba().
    pal$paper <- if (identical(preset, "dark")) {
      "rgba(28,28,30,0.94)"
    } else {
      "rgba(245,245,247,0.94)"
    }
  }
  pal
}

#' ggplot2 theme that follows glass light/dark ink
#'
#' Transparent panel and plot backgrounds so the page wallpaper shows through
#' glass cards. Use `surface = "opaque"` for a near-solid panel when dense
#' charts must stay readable. Requires ggplot2 (a Suggests dependency).
#'
#' @param preset `"light"` or `"dark"`. When `NULL`, uses
#'   [glass_resolved_preset()].
#' @param base_size Base font size passed to [ggplot2::theme_minimal()].
#' @param input Optional Shiny `input`.
#' @param surface `"clear"` or `"opaque"`. See [glass_plot_colors()].
#' @param ... Additional [ggplot2::theme()] arguments.
#'
#' @return A ggplot2 theme object.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     ggplot2::geom_point() +
#'     theme_glass("light")
#' }
theme_glass <- function(preset = NULL, base_size = 13, input = NULL,
                        surface = c("clear", "opaque"), ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop('Install ggplot2 to use theme_glass(): install.packages("ggplot2")', call. = FALSE)
  }
  pal <- glass_plot_colors(preset, input, surface = surface)
  # grid does not accept CSS rgba(); use an #RRGGBBAA color.
  grid_col <- grDevices::adjustcolor(pal$ink, alpha.f = 0.12)
  paper_fill <- if (identical(pal$surface, "opaque")) {
    grDevices::adjustcolor(
      if (identical(pal$preset, "dark")) "#1c1c1e" else "#f5f5f7",
      alpha.f = 0.94
    )
  } else {
    NA
  }
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = paper_fill, color = NA),
      plot.background = ggplot2::element_rect(fill = paper_fill, color = NA),
      legend.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(color = grid_col, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      text = ggplot2::element_text(color = pal$ink),
      axis.text = ggplot2::element_text(color = pal$ink),
      axis.title = ggplot2::element_text(color = pal$ink),
      plot.title = ggplot2::element_text(color = pal$ink, face = "bold"),
      plot.subtitle = ggplot2::element_text(color = pal$ink),
      legend.text = ggplot2::element_text(color = pal$ink),
      legend.title = ggplot2::element_text(color = pal$ink),
      ...
    )
}

#' plotly layout that matches glass chrome
#'
#' Transparent paper/plot backgrounds and ink that follows the resolved
#' preset. Requires plotly. Call as `plotly_glass(p)` or
#' `do.call(plotly::layout, c(list(p), plotly_glass()))`.
#'
#' @param p Optional plotly object. When `NULL`, returns a named list of
#'   layout arguments.
#' @param preset,input,surface See [glass_plot_colors()].
#'
#' @return `p` with layout applied, or a list of layout arguments.
#' @export
plotly_glass <- function(p = NULL, preset = NULL, input = NULL,
                         surface = c("clear", "opaque")) {
  pal <- glass_plot_colors(preset, input, surface = surface)
  layout_args <- list(
    paper_bgcolor = pal$paper,
    plot_bgcolor = pal$paper,
    font = list(
      color = pal$ink,
      family = "-apple-system, BlinkMacSystemFont, sans-serif"
    ),
    xaxis = list(
      gridcolor = pal$grid,
      zerolinecolor = pal$grid,
      color = pal$ink,
      tickfont = list(color = pal$ink)
    ),
    yaxis = list(
      gridcolor = pal$grid,
      zerolinecolor = pal$grid,
      color = pal$ink,
      tickfont = list(color = pal$ink)
    ),
    legend = list(bgcolor = pal$paper, font = list(color = pal$ink)),
    margin = list(l = 56, r = 24, t = 36, b = 64)
  )
  if (is.null(p)) {
    return(layout_args)
  }
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop('Install plotly to use plotly_glass(p): install.packages("plotly")', call. = FALSE)
  }
  do.call(plotly::layout, c(list(p), layout_args))
}

#' Plot / table surface select
#'
#' Drop-in [shiny::selectInput()] that applies
#' `window.shinyglass.setPlotSurface()` immediately. Pair with
#' [observe_glass_plot_surface()] so the server stays in sync.
#'
#' @param inputId The `input` slot that will be used to access the value.
#' @param label Display label (or `NULL` for none).
#' @param selected `"clear"` or `"opaque"`.
#' @param width The width of the input (e.g. `"100%"`).
#'
#' @return A [shiny::selectInput()] tag marked for client bindings.
#' @seealso [observe_glass_plot_surface()], [glass_theme()]
#' @export
glass_plot_surface_input <- function(
    inputId = "plot_surface",
    label = "Plot / table surface",
    selected = c("clear", "opaque"),
    width = NULL) {
  selected <- match.arg(selected)
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  sel <- shiny::selectInput(
    inputId = inputId,
    label = label,
    choices = c(
      "Clear (show wallpaper)" = "clear",
      "Opaque (readable)" = "opaque"
    ),
    selected = selected,
    width = width
  )
  .glass_mark_select(
    sel, inputId, "glass-plot-surface-input", "data-glass-plot-surface-input"
  )
}

#' Observe [glass_plot_surface_input()] on the server
#'
#' @param input,session Shiny `input` and `session` objects.
#' @param inputId Same id passed to [glass_plot_surface_input()].
#' @return An [shiny::observeEvent()] observer (invisibly).
#' @export
observe_glass_plot_surface <- function(input, session, inputId = "plot_surface") {
  if (missing(input) || missing(session)) {
    stop("`input` and `session` are required.", call. = FALSE)
  }
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  shiny::observeEvent(
    input[[inputId]],
    {
      val <- input[[inputId]]
      if (is.null(val) || !val %in% c("clear", "opaque")) {
        return()
      }
      update_glass_theme(session, plot_surface = val)
    },
    ignoreInit = TRUE,
    ignoreNULL = TRUE
  )
}

#' DT options that pair with glass plot surfaces
#'
#' Host CSS already skins DataTables (pagination, ink, opaque/clear panels).
#' This helper is optional: it keeps tables inside glass cards with wrapping
#' headers and in-card horizontal scroll — the same contract used by the
#' dashboard demo.
#'
#' @param ... Named DT `options` that override the defaults.
#' @param page_length Rows per page.
#' @param scroll_x Enable DataTables `scrollX` (useful on narrow viewports).
#'
#' @return A named list for `DT::datatable(options = )`.
#' @export
#' @examples
#' dt_options_glass(page_length = 8)
#' dt_options_glass(searching = FALSE, scroll_x = TRUE)
dt_options_glass <- function(..., page_length = 8, scroll_x = FALSE) {
  opts <- list(
    pageLength = page_length,
    dom = "tip",
    scrollX = isTRUE(scroll_x),
    autoWidth = FALSE
  )
  extra <- list(...)
  for (nm in names(extra)) {
    opts[[nm]] <- extra[[nm]]
  }
  opts
}

#' gt table options that match glass chrome
#'
#' Transparent table chrome so glass cards show through. Requires gt.
#'
#' @param data A [gt::gt()] table (or data frame, which is passed to `gt()`).
#' @param preset,input,surface See [glass_plot_colors()].
#'
#' @return A gt table.
#' @export
gt_theme_glass <- function(data, preset = NULL, input = NULL,
                           surface = c("clear", "opaque")) {
  if (!requireNamespace("gt", quietly = TRUE)) {
    stop('Install gt to use gt_theme_glass(): install.packages("gt")', call. = FALSE)
  }
  pal <- glass_plot_colors(preset, input, surface = surface)
  if (!inherits(data, "gt_tbl")) {
    data <- gt::gt(data)
  }
  table_bg <- if (identical(pal$surface, "opaque")) pal$paper else "transparent"
  gt::tab_options(
    data,
    table.background.color = table_bg,
    heading.background.color = table_bg,
    column_labels.background.color = table_bg,
    row.striping.background_color = "transparent",
    table.font.color = pal$ink,
    table.border.top.color = "transparent",
    table.border.bottom.color = "transparent",
    table.border.left.color = "transparent",
    table.border.right.color = "transparent"
  )
}
