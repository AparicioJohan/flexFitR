#' Plot Function
#'
#' This function plots a user-defined function over a specified interval and annotates the plot with
#' the calculated Area Under the Curve (AUC) and parameter values. The aim of `plot_fn` is to allow users to play with
#' different Starting Values in their functions before fitting any models.
#'
#' @param fn A character string representing the name of the function to be plotted. Default is "fn_piwise".
#' @param params A named numeric vector of parameters to be passed to the function. Default is \code{c(t1 = 34.9, t2 = 61.8, k = 100)}.
#' @param interval A numeric vector of length 2 specifying the interval over which the function is to be plotted. Default is \code{c(0, 100)}.
#' @param n_points An integer specifying the number of points to be used for plotting. Default is 1000.
#' @param auc Print AUC in the plot? Default is \code{FALSE}.
#' @param x_auc_label A numeric value specifying the x-coordinate for the AUC label. Default is \code{NULL}.
#' @param y_auc_label A numeric value specifying the y-coordinate for the AUC label. Default is \code{NULL}.
#' @param auc_label_size A numeric value specifying the size of the AUC label text. Default is 3.
#' @param param_label_size A numeric value specifying the size of the parameter label text. Default is 3.
#' @param base_size A numeric value specifying the base size for the plot's theme. Default is 12.
#' @param color A character string specifying the color for the plot lines and area fill. Default is "red".
#' @param label_color A character string specifying the color for the labels. Default is "grey30".
#'
#' @return A ggplot object representing the plot.
#' @export
#'
#' @examples
#' # Example usage
#' plot_fn(
#'   fn = "fn_piwise",
#'   params = c(t1 = 34.9, t2 = 61.8, k = 100),
#'   interval = c(0, 100),
#'   n_points = 1000
#' )
#' plot_fn(
#'   fn = "fn_lin_pl_lin",
#'   params <- c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   interval = c(0, 100),
#'   n_points = 1000,
#'   base_size = 12
#' )
plot_fn <- function(fn = "fn_piwise",
                    params = c(t1 = 34.9, t2 = 61.8, k = 100),
                    interval = c(0, 100),
                    n_points = 1000,
                    auc = FALSE,
                    x_auc_label = NULL,
                    y_auc_label = NULL,
                    auc_label_size = 4,
                    param_label_size = 4,
                    base_size = 12,
                    color = "red",
                    label_color = "grey30") {
  t <- seq(interval[1], interval[2], length.out = n_points)
  arg <- names(formals(fn))[-1]
  values <- paste(params, collapse = ", ")
  string <- paste("sapply(t, FUN = ", fn, ", ", values, ")", sep = "")
  y_hat <- eval(parse(text = string))
  dt <- data.frame(x = t, hat = y_hat)
  auc_val <- dt |>
    mutate(trapezoid_area = (lead(hat) + hat) / 2 * (lead(x) - x)) |>
    filter(!is.na(trapezoid_area)) |>
    summarise(auc = round(sum(trapezoid_area), 2)) |>
    pull(auc)
  title <- create_call(fn)
  info <- paste(paste(arg, round(params, 3), sep = " = "), collapse = "\n")

  x.label_params <- interval[1] + (interval[2] - interval[1]) * 0.15
  y.label_params <- min(dt$hat) + (max(dt$hat) - min(dt$hat)) * 0.8
  x.label_auc <- interval[1] + (interval[2] - interval[1]) * 0.7
  y.label_auc <- min(dt$hat) + (max(dt$hat) - min(dt$hat)) * 0.3

  p0 <- dt |>
    ggplot(aes(x = x, y = hat)) +
    geom_text(
      label = info,
      x = x.label_params,
      y = y.label_params,
      stat = "unique",
      size = param_label_size,
      color = label_color
    ) +
    geom_line(color = color) +
    theme_classic(base_size = base_size) +
    labs(y = "y", title = title)
  if (auc) {
    p0 <- p0 +
      geom_area(fill = color, alpha = 0.05) +
      geom_text(
        label = paste0("AUC = ", auc_val),
        x = ifelse(is.null(x_auc_label), x.label_auc, x_auc_label),
        y = ifelse(is.null(y_auc_label), y.label_auc, y_auc_label),
        size = auc_label_size,
        stat = "unique",
        color = label_color
      )
  }
  return(p0)
}


#' Plot an object of class \code{modeler}
#'
#' @description Create several plots for an object of class \code{modeler}
#' @aliases plot.modeler
#' @param x An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param id To avoid too many plots in one figure. Filter by group Id.
#' @param type Numeric 1, 2, or 3. To specify the type of plot. Default is 1.
#'  Type 4, 5 and 6 are experimental. See details.
#' @param label_size Label size. 3 by default.
#' @param base_size Base font size, given in pts.
#' @param color color for geom_line when type 1. Default is "red".
#' @param parm If type is equal to 2 it must be a vector of names of the parameters. If NULL, all parameters are considered.
#' @param n_points Number of points to interpolate along the x axis. Default is 2000.
#' @param title Optional string character to add a title to the plot.
#' @param ... Further graphical parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method plot modeler
#' @return A ggplot object.
#' @export
#' @details
#' \describe{
#'   \item{\code{type = 1}}{Raw Data + Fitted Curve}
#'   \item{\code{type = 2}}{Coefficients + Confindence Intervals}
#'   \item{\code{type = 3}}{Fitted Curve + Group by Color}
#'   \item{\code{type = 4}}{Fitted curve + Confindence Intervals}
#'   \item{\code{type = 5}}{First Derivative + Confindence Intervals}
#'   \item{\code{type = 6}}{Second Derivative + Confindence Intervals}
#' }
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' # Example 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(1:3),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' print(mod_1)
#' plot(mod_1, id = 1:2)
#' plot(mod_1, id = 1:3, type = 2, label_size = 10)
#' @import ggplot2
#' @import dplyr
#' @importFrom stats quantile
#' @importFrom stats reorder
plot.modeler <- function(x,
                         id = NULL,
                         type = 1,
                         label_size = 4,
                         base_size = 14,
                         color = "red",
                         parm = NULL,
                         n_points = 2000,
                         title = NULL, ...) {
  data <- x$dt |> select(uid, var, x, y, .fitted)
  param <- x$param
  fn <- x$fn
  dt <- full_join(data, y = param, by = c("uid"))
  if (is.null(id)) {
    id <- dt$uid[1]
  } else {
    if (!all(id %in% unique(dt$uid))) {
      stop("ids not found in x.")
    }
  }
  dt <- dt |>
    filter(uid %in% id) |>
    droplevels()
  param <- param |>
    filter(uid %in% id) |>
    droplevels()

  max_x <- max(dt$x, na.rm = TRUE)
  min_x <- min(dt$x, na.rm = TRUE)
  sq <- seq(min_x, max_x, length.out = n_points)

  func_dt <- full_join(
    x = expand.grid(x = sq, uid = unique(dt$uid)),
    y = param,
    by = "uid"
  ) |>
    group_by(x, uid) |>
    mutate(dens = !!fn) |>
    ungroup()

  label <- unique(dt$var)

  if (type == 1) {
    p0 <- dt |>
      ggplot() +
      geom_point(aes(x = x, y = y)) +
      geom_line(data = func_dt, aes(x = x, y = dens), color = color) +
      theme_classic(base_size = base_size) +
      facet_wrap(~uid) +
      labs(y = label, title = title)
  }
  if (type == 2) {
    cc_table <- confint.modeler(x, parm = parm, id = id)
    p0 <- cc_table |>
      ggplot(aes(x = reorder(uid, -solution), y = solution)) +
      geom_point() +
      geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.25) +
      facet_wrap(~coefficient, scales = "free_y") +
      labs(x = "Group", title = title) +
      theme_classic(base_size = base_size) +
      theme(axis.text.x = element_text(size = label_size))
  }
  if (type == 3) {
    p0 <- dt |>
      ggplot() +
      geom_line(
        data = func_dt,
        mapping = aes(x = x, y = dens, group = uid, color = as.factor(uid)),
      ) +
      theme_classic(base_size = base_size) +
      labs(y = label, color = "uid", title = title)
  }
  if (type %in% c(4, 5, 6)) {
    tp <- switch(
      EXPR = as.character(type),
      `4` = "point",
      `5` = "fd",
      `6` = "sd"
    )
    dt_ci <- predict.modeler(object = x, x = sq, type = tp, id = id) |>
      mutate(
        ci_lower = predicted.value - 1.96 * std.error,
        ci_upper = predicted.value + 1.96 * std.error
      )
    p0 <- dt_ci |>
      ggplot() +
      geom_ribbon(
        mapping = aes(x = x_new, ymin = ci_lower, ymax = ci_upper),
        fill = "blue",
        alpha = 0.5
      ) +
      geom_line(
        mapping = aes(x = x_new, y = predicted.value, group = uid),
        color = color
      ) +
      theme_classic(base_size = base_size) +
      facet_wrap(~uid) +
      labs(y = label, x = "x", title = title)
  }
  return(p0)
}

#' Plot an object of class \code{explorer}
#'
#' @description
#' Creates various plots for an object of class \code{explorer}.
#' Depending on the specified type, the function can generate plots that show correlations between variables over x, correlations between x values for each variable, or the evolution of variables over x.
#'
#' @param x An object inheriting from class \code{explorer}, resulting from executing the function \code{explorer()}.
#' @param type Character string or number specifying the type of plot to generate. Available options are:
#' \describe{
#'   \item{\code{"var_by_x" or 1}}{Plots correlations between variables over x (default).}
#'   \item{\code{"x_by_var" or 2}}{Plots correlations between x points for each variable (y).}
#'   \item{\code{"evolution" or 3}}{Plot the evolution of the variables (y) over x.}
#'   \item{\code{"xy" or 4}}{Scatterplot (x, y)}
#' }
#' @param signif Logical. If \code{TRUE}, adds p-values to the correlation plot labels. Default is \code{FALSE}. Only works with type 1 and 2.
#' @param label_size Numeric. Size of the labels in the plot. Default is 4. Only works with type 1 and 2.
#' @param method Character string specifying the method for correlation calculation. Available options are \code{"pearson"} (default), \code{"spearman"}, and \code{"kendall"}. Only works with type 1 and 2.
#' @param filter_var Character vector specifying the variables to exclude from the plot.
#' @param id Optional unique identifier to filter the evolution type of plot. Default is \code{NULL}. Only works with type 3.
#' @param n_row Integer specifying the number of rows to use in \code{facet_wrap()}. Default is \code{NULL}. Only works with type 1 and 2.
#' @param n_col Integer specifying the number of columns to use in \code{facet_wrap()}. Default is \code{NULL}. Only works with type 1 and 2.
#' @param base_size Numeric. Base font size for the plot. Default is 13.
#' @param return_gg Logical. If \code{TRUE}, returns the ggplot object instead of printing it. Default is \code{FALSE}.
#' @param add_avg Logical. If \code{TRUE}, returns evolution plot with the average trend across groups. Default is \code{FALSE}.
#' @param ... Further graphical parameters for future improvements.
#'
#' @return A ggplot object and an invisible data.frame containing the correlation table when \code{type} is \code{"var_by_x"} or \code{"x_by_var"}.
#'
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- explorer(dt_potato, x = DAP, y = c(Canopy, PH), id = Plot)
#' table <- plot(results, label_size = 4, signif = TRUE, n_row = 2)
#' table
#' plot(results, type = "x_by_var", label_size = 4, signif = TRUE)
#' @import tidyr
#' @import agriutilities
plot.explorer <- function(x,
                          type = "var_by_x",
                          label_size = 4,
                          signif = FALSE,
                          method = "pearson",
                          filter_var = NULL,
                          id = NULL,
                          n_row = NULL,
                          n_col = NULL,
                          base_size = 13,
                          return_gg = FALSE,
                          add_avg = FALSE, ...) {
  .keep <- x$metadata
  colours <- c("#db4437", "white", "#4285f4")
  flt <- x$summ_vars |>
    filter(`miss%` <= 0.2) |> #  & SD > 0
    droplevels() |>
    mutate(id = paste(var, x, sep = "_")) |>
    pull(id)

  data <- x$dt_long |>
    mutate(id = paste(var, x, sep = "_")) |>
    filter(id %in% flt) |>
    select(-id) |>
    droplevels()

  if (length(filter_var) >= 1) {
    data <- filter(data, !var %in% filter_var)
  }

  # Correlation between var by x
  if (type == "var_by_x" || type == 1) {
    vars <- unique(data$var)
    if (length(vars) <= 1) {
      stop("Only one trait available. 'var_by_x' plot not informative.")
    }
    var_by_x <- data |>
      pivot_wider(names_from = var, values_from = y) |>
      select(-c(uid, all_of(.keep))) |>
      nest_by(x) |>
      mutate(
        mat = list(
          suppressWarnings(
            gg_cor(return_table = TRUE, data = data, method = method)
          )
        )
      ) |>
      reframe(mat)
    p1 <- var_by_x |>
      ggplot(aes(x = col, y = row, fill = name.x)) +
      geom_tile(color = "gray") +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = base_size) +
      {
        if (signif) {
          geom_text(
            aes(x = col, y = row, label = label),
            color = var_by_x$txtCol,
            size = label_size
          )
        }
      } +
      {
        if (!signif) {
          geom_text(
            aes(x = col, y = row, label = name.x),
            color = var_by_x$txtCol,
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
      facet_wrap(~x, nrow = n_row, ncol = n_col)
    table <- var_by_x |>
      rename(corr = name.x, p.value = value.y, n = value) |>
      select(-label, -txtCol)
  }

  # Correlation between x by var
  if (type == "x_by_var" || type == 2) {
    x_by_var <- data |>
      pivot_wider(names_from = x, values_from = y) |>
      select(-c(uid, all_of(.keep))) |>
      nest_by(var) |>
      mutate(
        mat = list(
          suppressWarnings(
            gg_cor(return_table = TRUE, data = data, method = method)
          )
        )
      ) |>
      reframe(mat)
    p1 <- x_by_var |>
      ggplot(aes(x = col, y = row, fill = name.x)) +
      geom_tile(color = "gray") +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = base_size) +
      {
        if (signif) {
          geom_text(
            aes(x = col, y = row, label = label),
            color = x_by_var$txtCol,
            size = label_size
          )
        }
      } +
      {
        if (!signif) {
          geom_text(
            aes(x = col, y = row, label = name.x),
            color = x_by_var$txtCol,
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
      facet_wrap(~var, nrow = n_row, ncol = n_col)
    table <- x_by_var |>
      rename(corr = name.x, p.value = value.y, n = value) |>
      select(-label, -txtCol)
  }

  if (type == "evolution" || type == 3) {
    dt_avg <- data |>
      group_by(x, var) |>
      summarise(y = mean(y, na.rm = TRUE), .groups = "drop")

    if (!is.null(id)) {
      if (!all(id %in% unique(data$uid))) {
        stop("ids not found in data")
      }
      data <- filter(data, uid %in% id)
    }

    p1 <- data |>
      ggplot(aes(x = x, y = y)) +
      geom_vline(
        data = dt_avg,
        mapping = aes(xintercept = x),
        linetype = 2, color = "grey90"
      ) +
      geom_line(color = "grey", aes(group = uid)) +
      facet_wrap(~var, scales = "free_y") +
      theme_classic(base_size = base_size) +
      labs(x = "x", y = NULL, nrow = n_row, ncol = n_col)
    if (add_avg) {
      p1 <- p1 + geom_line(data = dt_avg, color = "red") +
        geom_point(data = dt_avg, color = "red")
    }
  }

  if (type == "xy" || type == 4) {
    if (!is.null(id)) {
      if (!all(id %in% unique(data$uid))) {
        stop("ids not found in data")
      }
      data <- filter(data, uid %in% id)
    }
    p1 <- data |>
      ggplot(aes(x = x, y = y)) +
      geom_point() +
      theme_classic(base_size = base_size) +
      labs(x = "x", y = "y", nrow = n_row, ncol = n_col)
    lv <- length(unique(data$var))
    if (lv > 1) {
      p1 <- p1 +
        facet_wrap(~var, scales = "free_y")
    }
  }


  if (return_gg) {
    return(p1)
  }
  print(p1)
  if (type %in% c("x_by_var", "var_by_x")) {
    invisible(table)
  }
}
