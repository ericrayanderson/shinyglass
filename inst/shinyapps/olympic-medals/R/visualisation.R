.medal_subtitle <- function(medal_types) {
  labels <- c(GOLD = "Gold", SILVER = "Silver", BRONZE = "Bronze")
  words <- unname(labels[intersect(names(labels), unique(as.character(medal_types)))])
  if (!length(words)) {
    return("Number of medals")
  }
  if (length(words) == 1L) {
    return(paste("Number of", words, "medals"))
  }
  paste0(
    "Number of ",
    paste(words[-length(words)], collapse = ", "),
    " and ",
    words[[length(words)]],
    " medals"
  )
}

visualisation_medal <- function(x, input = NULL) {
  col_medailles <- c("BRONZE" = "#996B4F", "SILVER" = "#969696", "GOLD" = "#9F8F5E")
  x$medal_type <- factor(x$medal_type, levels = names(col_medailles))
  p <- ggplot(data = x, mapping = aes(
    y = reorder(country_name, n_tot), x = n_medal,
    fill = factor(medal_type)
  )) +
    geom_col() +
    scale_fill_manual(values = col_medailles, breaks = names(col_medailles)[length(col_medailles):1]) +
    labs(
      title = "An overview of olympic medals",
      subtitle = .medal_subtitle(x$medal_type),
      x = "number of medals",
      fill = "medal type"
    ) +
    guides(fill = "none")
  p <- p + ggplot2::theme_minimal(base_size = 15)
  if (requireNamespace("shinyglass", quietly = TRUE)) {
    glass_th <- tryCatch(
      shinyglass::theme_glass(input = input, base_size = 15),
      error = function(e) NULL
    )
    if (!is.null(glass_th)) {
      p <- p + glass_th
    }
  }
  p + ggplot2::theme(axis.title.y = ggplot2::element_blank())
}

table_medal <- function(data) {
  columns <- list(
    country_name = colDef(
      name = "Country Name"
    ),
    n_tot = colDef(
      name = "Total Medals"
    )
  )
  if (hasName(data, "BRONZE")) {
    columns$BRONZE <- colDef(
      name = "BRONZE",
      html = TRUE,
      header = function(x) {
        tags$div(icon("medal"), "BRONZE", style = "color: #996B4F;")
      }
    )
  }
  if (hasName(data, "SILVER")) {
    columns$SILVER <- colDef(
      name = "SILVER",
      html = TRUE,
      header = function(x) {
        tags$div(icon("medal"), "SILVER", style = "color: #969696")
      }
    )
  }
  if (hasName(data, "GOLD")) {
    columns$GOLD <- colDef(
      name = "GOLD",
      html = TRUE,
      header = function(x) {
        tags$div(icon("medal"), "GOLD", style = "color: #9F8F5E")
      }
    )
  }
  reactable(
    data = data,
    columns = columns
  )
}
