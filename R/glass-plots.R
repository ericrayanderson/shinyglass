#' Ink and grid colors for the current glass appearance
#'
#' @param preset `"light"` or `"dark"`. When `NULL`, uses
#'   [glass_resolved_preset()] on `input`.
#' @param input Optional Shiny `input` (used when `preset` is `NULL`).
#'
#' @return A list with `preset`, `ink`, `grid`, `fill`, and `paper`.
#' @export
glass_plot_colors <- function(preset = NULL, input = NULL) {
  if (is.null(preset)) {
    preset <- glass_resolved_preset(input)
  }
  preset <- match.arg(preset, c("light", "dark"))
  if (identical(preset, "dark")) {
    list(
      preset = "dark",
      ink = "#f5f5f7",
      grid = "rgba(245,245,247,0.12)",
      fill = "#0A84FF",
      paper = "rgba(0,0,0,0)"
    )
  } else {
    list(
      preset = "light",
      ink = "#1d1d1f",
      grid = "rgba(29,29,31,0.10)",
      fill = "#007AFF",
      paper = "rgba(0,0,0,0)"
    )
  }
}

#' ggplot2 theme that follows glass light/dark ink
#'
#' Transparent panel and plot backgrounds so the page wallpaper shows through
#' glass cards. Requires ggplot2 (a Suggests dependency).
#'
#' @param preset `"light"` or `"dark"`. When `NULL`, uses
#'   [glass_resolved_preset()].
#' @param base_size Base font size passed to [ggplot2::theme_minimal()].
#' @param input Optional Shiny `input`.
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
theme_glass <- function(preset = NULL, base_size = 13, input = NULL, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop('Install ggplot2 to use theme_glass(): install.packages("ggplot2")', call. = FALSE)
  }
  pal <- glass_plot_colors(preset, input)
  # grid does not accept CSS rgba(); use an #RRGGBBAA color.
  grid_col <- grDevices::adjustcolor(pal$ink, alpha.f = 0.12)
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = NA, color = NA),
      plot.background = ggplot2::element_rect(fill = NA, color = NA),
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
#' @param preset,input See [glass_plot_colors()].
#'
#' @return `p` with layout applied, or a list of layout arguments.
#' @export
plotly_glass <- function(p = NULL, preset = NULL, input = NULL) {
  pal <- glass_plot_colors(preset, input)
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

#' gt table options that match glass chrome
#'
#' Transparent table chrome so glass cards show through. Requires gt.
#'
#' @param data A [gt::gt()] table (or data frame, which is passed to `gt()`).
#' @param preset,input See [glass_plot_colors()].
#'
#' @return A gt table.
#' @export
gt_theme_glass <- function(data, preset = NULL, input = NULL) {
  if (!requireNamespace("gt", quietly = TRUE)) {
    stop('Install gt to use gt_theme_glass(): install.packages("gt")', call. = FALSE)
  }
  pal <- glass_plot_colors(preset, input)
  if (!inherits(data, "gt_tbl")) {
    data <- gt::gt(data)
  }
  gt::tab_options(
    data,
    table.background.color = "transparent",
    heading.background.color = "transparent",
    column_labels.background.color = "transparent",
    row.striping.background_color = "transparent",
    table.font.color = pal$ink,
    table.border.top.color = "transparent",
    table.border.bottom.color = "transparent",
    table.border.left.color = "transparent",
    table.border.right.color = "transparent"
  )
}
