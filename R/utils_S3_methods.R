#' Plot an object of class \code{canopy_HTP}
#'
#' @description Create several plots for an object of class \code{canopy_HTP}
#' @aliases plot.canopy_HTP
#' @param x An object inheriting from class \code{canopy_HTP} resulting of
#' executing the function \code{canopy_HTP()}
#' @param plot_id To avoid too many plots in one figure. Filter by Plot Id.
#' @param label_size Label size. 3 by default.
#' @param base_size Base font size, given in pts.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot canopy_HTP
#' @return A ggplot object.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' out <- canopy_HTP(results, plot_id = 22)
#' plot(out)
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
plot.canopy_HTP <- function(x,
                            plot_id = NULL,
                            label_size = 4,
                            base_size = 14, ...) {
  dt <- x$dt |>
    full_join(y = x$param, by = c("plot", "row", "range", "genotype"))
  if (is.null(plot_id)) {
    plot_id <- dt$plot[1]
  } else {
    dt <- dt |>
      filter(plot %in% plot_id) |>
      droplevels()
  }
  p0 <- dt |>
    ggplot(
      aes(x = time)
    ) +
    geom_point(aes(y = corrected)) +
    geom_segment(
      aes(
        x = t1,
        xend = t2,
        y = intercept + slope * t1,
        yend = intercept + slope * t2,
      ),
      color = "red"
    ) +
    geom_segment(aes(x = 0, xend = t1, y = 0, yend = 0), color = "red") +
    geom_segment(
      aes(
        x = t2,
        xend = max(time),
        y = max,
        yend = max
      ),
      color = "red"
    ) +
    geom_vline(aes(xintercept = c(t1)), linetype = 2) +
    geom_vline(aes(xintercept = c(t2)), linetype = 2) +
    theme_classic(base_size = base_size) +
    ylim(c(0, NA)) +
    facet_wrap(~plot) +
    geom_text(
      aes(
        label = paste0("t1 = ", round(t1, 2), "\n", "t2 = ", round(t2, 2)),
        x = quantile(time, probs = 0.08)[1],
        y = (max(corrected) - min(corrected)) / 2
      ),
      stat = "unique",
      size = label_size, colour = "black"
    ) +
    labs(y = "Canopy (%)")
  return(p0)
}


#' Plot an object of class \code{read_HTP}
#'
#' @description Create several plots for an object of class \code{read_HTP}
#' @aliases plot.read_HTP
#' @param x An object inheriting from class \code{read_HTP} resulting of
#' executing the function \code{read_HTP()}
#' @param type  Character string. Available options are:
#'  "trait_by_time", "time_by_trait", "evolution". "trait_by_time" by default.
#' @param signif TRUE or FALSE. Add the pvalue to the correlations plot.
#' @param label_size Label size. 4 by default.
#' @param method method="pearson" is the default value. The alternatives to be
#'  passed to cor are "spearman" and "kendall". These last two are much slower,
#'  particularly for big data sets.
#' @param filter_trait A character vector specifying the traits to remove from
#' the plot.
#' @param n_row Number of rows to use in face_wrap(). NULL by default.
#' @param n_col Number of columns to use in face_wrap(). NULL by default.
#' @param base_size Base font size, given in pts.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot read_HTP
#' @return A ggplot object and an invisible data.frame
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' table <- plot(results, label_size = 4, signif = TRUE, n_row = 2)
#' table
#' plot(results, type = "time_by_trait", label_size = 4, signif = TRUE)
#' @import tidyr
#' @import agriutilities
plot.read_HTP <- function(x,
                          type = "trait_by_time",
                          label_size = 4,
                          signif = FALSE,
                          method = "pearson",
                          filter_trait = NULL,
                          n_row = NULL,
                          n_col = NULL,
                          base_size = 13, ...) {
  colours <- c("#db4437", "white", "#4285f4")
  flt <- x$summ_traits |>
    filter(`miss%` <= 0.2 & SD > 0) |>
    droplevels() |>
    mutate(id = paste(trait, time, sep = "_")) |>
    pull(id)

  data <- x$dt_long |>
    mutate(id = paste(trait, time, sep = "_")) |>
    filter(id %in% flt) |>
    select(-id) |>
    droplevels()

  if (length(filter_trait) >= 1) {
    data <- filter(data, !trait %in% filter_trait)
  }

  # Correlation between traits by time
  if (type == "trait_by_time") {
    traits <- unique(data$trait)
    if (length(traits) <= 1) {
      stop("Only one trait available. 'trait_by_time' plot not informative.")
    }

    trait_by_time <- data |>
      pivot_wider(names_from = trait, values_from = value) |>
      select(-c(plot:genotype)) |>
      nest_by(time) |>
      mutate(
        mat = list(
          gg_cor(return_table = TRUE, data = data, method = method)
        )
      ) |>
      reframe(mat)
    p1 <- trait_by_time |>
      ggplot(
        aes(x = col, y = row, fill = name.x)
      ) +
      geom_tile(color = "gray") +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = base_size) +
      {
        if (signif) {
          geom_text(
            aes(x = col, y = row, label = label),
            color = trait_by_time$txtCol,
            size = label_size
          )
        }
      } +
      {
        if (!signif) {
          geom_text(
            aes(x = col, y = row, label = name.x),
            color = trait_by_time$txtCol,
            size = label_size
          )
        }
      } +
      scale_fill_gradient2(
        low = colours[1],
        mid = colours[2],
        high = colours[3]
      ) +
      theme(
        axis.text.x = element_text(angle = 40, hjust = 1),
        legend.position = "none",
        panel.grid.minor.x = element_blank(),
        panel.grid.major = element_blank()
      ) +
      facet_wrap(~time, nrow = n_row, ncol = n_col)

    table <- trait_by_time |>
      rename(corr = name.x, p.value = value.y, n = value) |>
      select(-label, -txtCol)
  }

  # Correlation between time-points by trait
  if (type == "time_by_trait") {
    time_by_trait <- data |>
      pivot_wider(names_from = time, values_from = value) |>
      select(-c(plot:genotype)) |>
      nest_by(trait) |>
      mutate(
        mat = list(
          gg_cor(return_table = TRUE, data = data, method = method)
        )
      ) |>
      reframe(mat)
    p1 <- time_by_trait |>
      ggplot(
        aes(x = col, y = row, fill = name.x)
      ) +
      geom_tile(color = "gray") +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = base_size) +
      {
        if (signif) {
          geom_text(
            aes(x = col, y = row, label = label),
            color = time_by_trait$txtCol,
            size = label_size
          )
        }
      } +
      {
        if (!signif) {
          geom_text(
            aes(x = col, y = row, label = name.x),
            color = time_by_trait$txtCol,
            size = label_size
          )
        }
      } +
      scale_fill_gradient2(
        low = colours[1],
        mid = colours[2],
        high = colours[3]
      ) +
      theme(
        axis.text.x = element_text(angle = 40, hjust = 1),
        legend.position = "none",
        panel.grid.minor.x = element_blank(),
        panel.grid.major = element_blank()
      ) +
      facet_wrap(~trait, nrow = n_row, ncol = n_col)
    table <- time_by_trait |>
      rename(corr = name.x, p.value = value.y, n = value) |>
      select(-label, -txtCol)
  }

  if (type == "evolution") {
    dt_avg <- data |>
      group_by(time, trait) |>
      summarise(value = mean(value, na.rm = TRUE), .groups = "drop")
    p1 <- data |>
      ggplot(
        aes(x = time, y = value)
      ) +
      geom_vline(
        data = dt_avg,
        mapping = aes(xintercept = time),
        linetype = 2, color = "grey90"
      ) +
      geom_line(color = "grey", aes(group = plot)) +
      geom_line(data = dt_avg, color = "red") +
      geom_point(data = dt_avg, color = "red") +
      facet_wrap(~trait, scales = "free_y") +
      theme_classic(base_size = base_size) +
      labs(x = "Time", y = NULL, nrow = n_row, ncol = n_col)
  }

  print(p1)
  if (type %in% c("time_by_trait", "trait_by_time")) {
    invisible(table)
  }
}
