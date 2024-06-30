#' Plot an object of class \code{canopy_HTP}
#'
#' @description Create several plots for an object of class \code{canopy_HTP}
#' @aliases plot.canopy_HTP
#' @param x An object inheriting from class \code{canopy_HTP} resulting of
#' executing the function \code{canopy_HTP()}
#' @param plot_id To avoid too many plots in one figure. Filter by Plot Id.
#' @param label_size Numeric. Size of the labels in the plot. Default is 4.
#' @param base_size Base font size, given in pts. Default is 14.
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
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(22, 40),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' names(out)
#' plot(out, c(22, 40))
#' out$param$deltaT <- out$param$t2 - out$param$t1
#' out$param$slope <- out$param$k / out$param$deltaT
#' out$param
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
plot.canopy_HTP <- function(x,
                            plot_id = NULL,
                            label_size = 4,
                            base_size = 14, ...) {
  data <- x$dt
  param <- x$param
  fn <- x$fn
  dt <- full_join(data, y = param, by = c("plot", "row", "range", "genotype"))
  if (is.null(plot_id)) {
    plot_id <- dt$plot[1]
  }
  dt <- dt |>
    filter(plot %in% plot_id) |>
    droplevels()
  param <- param |>
    filter(plot %in% plot_id) |>
    droplevels()

  max_x <- max(dt$time, na.rm = TRUE)
  min_x <- min(dt$time, na.rm = TRUE)
  sq <- seq(min_x, max_x, by = 0.05)

  func_dt <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(dens = !!fn) |>
    ungroup()

  p0 <- dt |>
    ggplot() +
    geom_point(aes(x = time, y = corrected)) +
    geom_line(data = func_dt, aes(x = time, y = dens), color = "red") +
    geom_vline(aes(xintercept = c(t1)), linetype = 2) +
    geom_vline(aes(xintercept = c(t2)), linetype = 2) +
    theme_classic(base_size = base_size) +
    ylim(c(0, NA)) +
    facet_wrap(~plot) +
    # geom_text(
    #   aes(
    #     label = paste0("t1 = ", round(t1, 2), "\n", "t2 = ", round(t2, 2)),
    #     x = quantile(time, probs = 0.08)[1],
    #     y = (max(corrected) - min(corrected)) / 2
    #   ),
    #   stat = "unique",
    #   size = label_size, colour = "black"
    # ) +
    labs(y = "Canopy (%)")
  return(p0)
}

#' Plot an object of class \code{height_HTP}
#'
#' @description Create several plots for an object of class \code{height_HTP}
#' @aliases plot.height_HTP
#' @param x An object inheriting from class \code{height_HTP} resulting of
#' executing the function \code{height_HTP()}
#' @param plot_id To avoid too many plots in one figure. Filter by Plot Id.
#' @param label_size Label size. 3 by default.
#' @param base_size Base font size, given in pts.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot height_HTP
#' @return A ggplot object.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_chips)
#' results <- read_HTP(
#'   data = dt_chips,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(60, 150),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' names(out)
#' plot(out, plot_id = c(60, 150))
#' ph_1 <- height_HTP(
#'   results = results,
#'   canopy = out,
#'   plant_height = "PH",
#'   add_zero = TRUE,
#'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
#'   return_method = TRUE,
#'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
#'   fn_sse = sse_exp2_exp,
#'   fn = quote(fn_exp2_exp(time, t1, t2, alpha, beta))
#' )
#' plot(x = ph_1, plot_id = c(60, 150))
#' ph_1$param
#'
#' ph_2 <- height_HTP(
#'   results = results,
#'   canopy = out,
#'   plant_height = "PH",
#'   add_zero = TRUE,
#'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
#'   return_method = TRUE,
#'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
#'   fn_sse = sse_exp2_lin,
#'   fn = quote(fn_exp2_lin(time, t1, t2, alpha, beta))
#' )
#' plot(x = ph_2, plot_id = c(60, 150))
#' ph_2$param
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
plot.height_HTP <- function(x,
                            plot_id = NULL,
                            label_size = 4,
                            base_size = 14, ...) {
  data <- x$dt
  param <- x$param
  fn <- x$fn
  dt <- full_join(
    x = data,
    y = param,
    by = c("plot", "row", "range", "genotype", "t1")
  )
  if (is.null(plot_id)) {
    plot_id <- dt$plot[1]
  } else {
    if (!all(plot_id %in% dt$plot)) {
      stop("Some of the plot_id were not found.")
    }
  }
  dt <- dt |>
    filter(plot %in% plot_id) |>
    droplevels()
  param <- param |>
    filter(plot %in% plot_id) |>
    droplevels()

  max_x <- max(dt$time, na.rm = TRUE)
  min_x <- min(dt$time, na.rm = TRUE)
  sq <- seq(min_x, max_x, by = 0.05)

  func_dt <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(dens = !!fn) |>
    ungroup()

  p0 <- dt |>
    ggplot() +
    geom_point(aes(x = time, y = value)) +
    geom_line(data = func_dt, aes(x = time, y = dens), color = "red") +
    geom_vline(aes(xintercept = c(t1)), linetype = 2) +
    geom_vline(aes(xintercept = c(DMC)), linetype = 2) +
    theme_classic(base_size = base_size) +
    facet_wrap(~plot) +
    labs(y = "Plant Height")
  return(p0)
}

#' Plot an object of class \code{maturity_HTP}
#'
#' @description Create several plots for an object of class \code{maturity_HTP}
#' @aliases plot.maturity_HTP
#' @param x An object inheriting from class \code{maturity_HTP} resulting of
#' executing the function \code{maturity_HTP()}
#' @param plot_id To avoid too many plots in one figure. Filter by Plot Id.
#' @param label_size Label size. 3 by default.
#' @param base_size Base font size, given in pts.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot maturity_HTP
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
#'   traits = c("Canopy", "GLI_2"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(195, 40),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' mat <- maturity_HTP(
#'   results = results,
#'   canopy = out,
#'   index = "GLI_2",
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn_sse = sse_lin_pl_lin,
#'   fn = quote(fn_lin_pl_lin(time, t1, t2, t3, k, beta))
#' )
#' plot(mat, plot_id = c(195, 40))
#' mat$param
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
plot.maturity_HTP <- function(x,
                              plot_id = NULL,
                              label_size = 4,
                              base_size = 14, ...) {
  data <- x$dt
  param <- x$param
  fn <- x$fn
  dt <- full_join(data, y = param, by = c("plot", "row", "range", "genotype"))
  if (is.null(plot_id)) {
    plot_id <- dt$plot[1]
  }
  dt <- dt |>
    filter(plot %in% plot_id) |>
    droplevels()
  param <- param |>
    filter(plot %in% plot_id) |>
    droplevels()

  max_x <- max(dt$time, na.rm = TRUE)
  min_x <- min(dt$time, na.rm = TRUE)
  sq <- seq(min_x, max_x, by = 0.05)

  func_dt <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(dens = !!fn) |>
    ungroup()

  p0 <- dt |>
    ggplot() +
    geom_point(aes(x = time, y = value)) +
    geom_line(data = func_dt, aes(x = time, y = dens), color = "red") +
    geom_vline(aes(xintercept = c(DE)), linetype = 2) +
    geom_vline(aes(xintercept = c(DMC)), linetype = 2) +
    theme_classic(base_size = base_size) +
    facet_wrap(~plot) +
    labs(y = "Maturity")
  return(p0)
}

#' Plot an object of class \code{modeler_HTP}
#'
#' @description Create several plots for an object of class \code{modeler_HTP}
#' @aliases plot.modeler_HTP
#' @param x An object inheriting from class \code{modeler_HTP} resulting of
#' executing the function \code{modeler_HTP()}
#' @param plot_id To avoid too many plots in one figure. Filter by Plot Id.
#' @param label_size Label size. 3 by default.
#' @param base_size Base font size, given in pts.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot modeler_HTP
#' @return A ggplot object.
#' @export
#' @examples
#' library(exploreHTP)
#' suppressMessages(library(dplyr))
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "GLI_2"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' mat <- modeler_HTP(
#'   x = results,
#'   index = "GLI_2",
#'   plot_id = c(195, 40),
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn = "fn_lin_pl_lin",
#' )
#' plot(mat, plot_id = c(195, 40))
#' mat$param
#'
#' can <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = c(195, 40),
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise"
#' )
#' plot(can, plot_id = c(195, 40))
#' can$param
#'
#' fixed_params <- results$dt_long |>
#'   filter(trait %in% "Canopy") |>
#'   group_by(plot, genotype) |>
#'   summarise(k = max(value, na.rm = TRUE), .groups = "drop")
#' can <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = c(195, 40),
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise",
#'   fixed_params = fixed_params
#' )
#' plot(can, plot_id = c(195, 40))
#' can$param
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
plot.modeler_HTP <- function(x,
                             plot_id = NULL,
                             label_size = 4,
                             base_size = 14, ...) {
  data <- x$dt
  param <- x$param
  fn <- x$fn
  dt <- full_join(data, y = param, by = c("plot", "row", "range", "genotype"))
  if (is.null(plot_id)) {
    plot_id <- dt$plot[1]
  }
  dt <- dt |>
    filter(plot %in% plot_id) |>
    droplevels()
  param <- param |>
    filter(plot %in% plot_id) |>
    droplevels()

  max_x <- max(dt$time, na.rm = TRUE)
  min_x <- min(dt$time, na.rm = TRUE)
  sq <- seq(min_x, max_x, by = 0.05)

  func_dt <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(dens = !!fn) |>
    ungroup()

  label <- unique(dt$trait)
  p0 <- dt |>
    ggplot() +
    geom_point(aes(x = time, y = value)) +
    geom_line(data = func_dt, aes(x = time, y = dens), color = "red") +
    theme_classic(base_size = base_size) +
    facet_wrap(~plot) +
    labs(y = label)
  return(p0)
}

#' Plot an Object of Class \code{read_HTP}
#'
#' @description
#' Creates various plots for an object of class \code{read_HTP}. Depending on the specified type, the function can generate plots that show correlations between traits over time, correlations between time points for each trait, or the evolution of traits over time.
#'
#' @param x An object inheriting from class \code{read_HTP}, resulting from executing the function \code{read_HTP()}.
#' @param type Character string specifying the type of plot to generate. Available options are:
#' \describe{
#'   \item{\code{"trait_by_time"}}{Plots correlations between traits over time (default).}
#'   \item{\code{"time_by_trait"}}{Plots correlations between time points for each trait.}
#'   \item{\code{"evolution"}}{Plots the evolution of traits over time.}
#' }
#' @param signif Logical. If \code{TRUE}, adds p-values to the correlation plot labels. Default is \code{FALSE}.
#' @param label_size Numeric. Size of the labels in the plot. Default is 4.
#' @param method Character string specifying the method for correlation calculation. Available options are \code{"pearson"} (default), \code{"spearman"}, and \code{"kendall"}.
#' @param filter_trait Character vector specifying the traits to exclude from the plot.
#' @param n_row Integer specifying the number of rows to use in \code{facet_wrap()}. Default is \code{NULL}.
#' @param n_col Integer specifying the number of columns to use in \code{facet_wrap()}. Default is \code{NULL}.
#' @param base_size Numeric. Base font size for the plot. Default is 13.
#' @param return_gg Logical. If \code{TRUE}, returns the ggplot object instead of printing it. Default is \code{FALSE}.
#' @param ... Further graphical parameters for future improvements.
#'
#' @return A ggplot object and an invisible data.frame containing the correlation table when \code{type} is \code{"trait_by_time"} or \code{"time_by_trait"}.
#'
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
                          base_size = 13,
                          return_gg = FALSE, ...) {
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
          suppressWarnings(
            gg_cor(return_table = TRUE, data = data, method = method)
          )
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
          suppressWarnings(
            gg_cor(return_table = TRUE, data = data, method = method)
          )
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

  if (return_gg) {
    return(p1)
  }

  print(p1)
  if (type %in% c("time_by_trait", "trait_by_time")) {
    invisible(table)
  }
}
