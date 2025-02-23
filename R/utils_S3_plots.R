#' Plot user-defined function
#'
#' This function plots a function over a specified interval and annotates the plot with
#' the calculated Area Under the Curve (AUC) and parameter values. The aim of `plot_fn` is to allow users to play with
#' different starting values in their functions before fitting any models.
#'
#' @param fn A character string representing the name of the function to be plotted. Default is "fn_linear_sat".
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
#'   fn = "fn_linear_sat",
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
plot_fn <- function(fn = "fn_linear_sat",
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
#' @description Creates several plots for an object of class \code{modeler}.
#' @aliases plot.modeler
#' @param x An object of class \code{modeler}, typically the result of calling \code{modeler()}.
#' @param id An optional group ID to filter the data for plotting, useful for avoiding overcrowded plots.
#' @param type Numeric value (1-6) to specify the type of plot to generate. Default is 1.
#' \describe{
#'   \item{\code{type = 1}}{Plot of raw data with fitted curves.}
#'   \item{\code{type = 2}}{Plot of coefficients with confidence intervals.}
#'   \item{\code{type = 3}}{Plot of fitted curves, colored by group.}
#'   \item{\code{type = 4}}{Plot of fitted curves with confidence intervals.}
#'   \item{\code{type = 5}}{Plot of first derivative with confidence intervals.}
#'   \item{\code{type = 6}}{Plot of second derivative with confidence intervals.}
#' }
#' @param label_size Numeric value for the size of labels. Default is 4.
#' @param base_size Numeric value for the base font size in pts. Default is 14.
#' @param color Character string specifying the color for the fitted line when \code{type = 1}. Default is "red".
#' @param color_points Character string specifying the color for the raw data points when \code{type = 1}. Default is "black".
#' @param parm Character vector specifying the parameters to plot for \code{type = 2}. If \code{NULL}, all parameters are included.
#' @param n_points Numeric value specifying the number of points for interpolation along the x-axis. Default is 2000.
#' @param title Optional character string to add a title to the plot.
#' @param add_ci Logical value indicating whether to add confidence intervals for \code{type = 4, 5, 6}. Default is \code{TRUE}.
#' @param color_ci Character string specifying the color of the confidence interval when \code{type = 4, 5, 6}. Default is "blue".
#' @param color_pi Character string specifying the color of the prediction interval when \code{type = 4}. Default is "red".
#' @param add_ribbon_ci Logical value indicating whether to add a ribbon for confidence intervals in \code{type = 4, 5, 6}. Default is \code{FALSE}.
#' @param add_ribbon_pi Logical value indicating whether to add a ribbon for prediction intervals in \code{type = 4}. Default is \code{FALSE}.
#' @param color_ribbon_ci Character string specifying the color of the ribbon (ci). Default is "blue".
#' @param color_ribbon_pi Character string specifying the color of the ribbon (pi). Default is "red".
#' @param ... Additional graphical parameters for future extensions.
#' @author Johan Aparicio [aut]
#' @method plot modeler
#' @return A \code{ggplot} object representing the specified plot.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' # Example 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_linear_sat",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(1:3)
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
                         color_points = "black",
                         parm = NULL,
                         n_points = 1000,
                         title = NULL,
                         add_ci = TRUE,
                         color_ci = "blue",
                         color_pi = "red",
                         add_ribbon_ci = FALSE,
                         add_ribbon_pi = FALSE,
                         color_ribbon_ci = "blue",
                         color_ribbon_pi = "red", ...) {
  dt <- x$dt |> select(uid, var, x, y, .fitted)
  if (is.null(id)) {
    id <- dt$uid[1]
  } else {
    if (!all(id %in% unique(dt$uid))) {
      stop("ids not found in x.")
    }
  }
  max_x <- max(dt$x, na.rm = TRUE)
  min_x <- min(dt$x, na.rm = TRUE)
  sq <- seq(min_x, max_x, length.out = n_points)
  # List of models
  expand_by_grp <- function(fit, seq) {
    curve <- fit$fn_name
    .fn <- create_call(curve)
    .uid <- fit$uid
    .param <- pull(fit$type, value, parameter)
    .func_dt <- data.frame(uid = .uid, x = seq, t(.param)) |>
      group_by(x, uid) |>
      mutate(dens = !!.fn, fn_name = curve) |>
      ungroup() |>
      dplyr::select(uid, x, dens, fn_name)
    return(.func_dt)
  }
  fit_list <- x$fit
  pos <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% id)
  fit_list <- fit_list[pos]
  # Density
  func_dt <- do.call(
    what = rbind,
    args = lapply(X = fit_list, FUN = expand_by_grp, seq = sq)
  ) |>
    as_tibble()
  dt <- droplevels(filter(dt, uid %in% id))
  label <- unique(dt$var)
  functions <- unique(func_dt$fn_name)
  n_funs <- length(functions)
  n_ids <- length(id)

  if (type == 1) {
    p0 <- dt |>
      ggplot() +
      geom_point(aes(x = x, y = y), color = color_points) +
      {
        if (n_funs == 1) {
          geom_line(
            data = func_dt,
            mapping = aes(x = x, y = dens, group = fn_name, linetype = fn_name),
            color = color
          )
        }
      } +
      {
        if (n_funs > 1) {
          geom_line(
            data = func_dt,
            mapping = aes(
              x = x,
              y = dens,
              group = fn_name,
              linetype = fn_name,
              color = fn_name
            )
          )
        }
      } +
      theme_classic(base_size = base_size) +
      labs(y = label, title = title)
    if (n_ids > 1) {
      p0 <- p0 + facet_wrap(~uid)
    }
    if (n_funs == 1) {
      p0 <- p0 + theme(legend.position = "none")
    } else if (n_funs > 1) {
      p0 <- p0 +
        scale_color_brewer(type = "qual", palette = "Dark2") +
        labs(color = "Model", linetype = "Model")
    }
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
    if (n_funs > 1) {
      p0 <- p0 + facet_wrap(fn_name ~ coefficient, scales = "free_y")
    }
  }
  if (type == 3) {
    p0 <- dt |>
      ggplot() +
      geom_line(
        data = func_dt,
        mapping = aes(
          x = x,
          y = dens,
          group = paste0(uid, "_", fn_name),
          color = as.factor(uid)
        ),
      ) +
      theme_classic(base_size = base_size) +
      labs(y = label, color = "uid", title = title) +
      scale_color_viridis_d(option = "D", direction = 1)
    if (n_funs > 1) {
      p0 <- p0 + facet_wrap(~fn_name)
    }
    if (n_funs == 1) {
      p0 <- p0 + theme(legend.position = "none")
    }
  }
  if (type %in% c(4, 5, 6)) {
    tp <- switch(
      EXPR = as.character(type),
      `4` = "point",
      `5` = "fd",
      `6` = "sd"
    )
    title_tmp <- switch(
      EXPR = as.character(type),
      `4` = "Fitted Curve",
      `5` = "1st Derivative",
      `6` = "2nd Derivative"
    )
    mse_dt <- do.call(
      what = rbind,
      args = lapply(x$fit, \(x) {
        n <- x$n_obs
        p <- x$p
        df <- n - p
        data.frame(
          uid = x$uid,
          n = n,
          p = p,
          df = df,
          mse = x$param$sse / df,
          fn_name = x$fn_name
        )
      })
    )
    dt_ci <- predict.modeler(object = x, x = sq, type = tp, id = id) |>
      left_join(y = mse_dt, by = c("uid", "fn_name")) |>
      mutate(std.error.p = sqrt(mse + std.error^2)) |>
      mutate(
        ci_lower = predicted.value + qt((1 - 0.95) / 2, df) * std.error,
        ci_upper = predicted.value - qt((1 - 0.95) / 2, df) * std.error,
        pi_lower = predicted.value + qt((1 - 0.95) / 2, df) * std.error.p,
        pi_upper = predicted.value - qt((1 - 0.95) / 2, df) * std.error.p
      )
    p0 <- dt_ci |>
      ggplot() +
      {
        if (add_ribbon_ci) {
          geom_ribbon(
            mapping = aes(
              x = x_new,
              ymin = ci_lower,
              ymax = ci_upper,
              group = fn_name
            ),
            fill = color_ribbon_ci,
            alpha = 0.1
          )
        }
      } +
      {
        if (add_ribbon_pi && type == 4) {
          geom_ribbon(
            mapping = aes(
              x = x_new,
              ymin = pi_lower,
              ymax = pi_upper,
              group = fn_name
            ),
            fill = color_ribbon_pi,
            alpha = 0.1
          )
        }
      } +
      {
        if (n_funs > 1 && !add_ci && !add_ribbon_ci && !add_ribbon_pi) {
          geom_line(
            mapping = aes(
              x = x_new,
              y = predicted.value,
              group = fn_name,
              linetype = fn_name,
              color = fn_name
            )
          )
        } else {
          geom_line(
            mapping = aes(
              x = x_new,
              y = predicted.value,
              group = paste0(uid, "_", fn_name)
            ),
            color = "black"
          )
        }
      } +
      {
        if (add_ci) {
          list(
            geom_line(
              mapping = aes(
                x = x_new,
                y = ci_lower,
                group = paste0(uid, "_", fn_name)
              ),
              linetype = 2,
              color = color_ci
            ),
            geom_line(
              mapping = aes(
                x = x_new,
                y = ci_upper,
                group = paste0(uid, "_", fn_name)
              ),
              linetype = 2,
              color = color_ci
            )
          )
        }
      } +
      {
        if (add_ci && type == 4) {
          list(
            geom_line(
              mapping = aes(
                x = x_new,
                y = pi_lower,
                group = paste0(uid, "_", fn_name)
              ),
              linetype = 2,
              color = color_pi
            ),
            geom_line(
              mapping = aes(
                x = x_new,
                y = pi_upper,
                group = paste0(uid, "_", fn_name)
              ),
              linetype = 2,
              color = color_pi
            )
          )
        }
      } +
      theme_classic(base_size = base_size) +
      labs(
        y = label,
        x = "x",
        color = "Model",
        fill = "Model",
        linetype = "Model",
        title = ifelse(is.null(title), title_tmp, title)
      )
    if (n_funs == 1 && n_ids == 1) {
      p0 <- p0
    }
    if (n_funs > 1 && n_ids == 1) {
      p0 <- p0 + facet_grid(~fn_name)
    }
    if (n_funs == 1 && n_ids > 1) {
      p0 <- p0 + facet_grid(~uid)
    }
    if (n_funs > 1 && n_ids > 1) {
      p0 <- p0 + facet_grid(uid ~ fn_name)
    }
    if (n_funs > 1 && !add_ci && !add_ribbon_ci && !add_ribbon_pi) {
      p0 <- p0 +
        facet_wrap(~ uid) +
        scale_color_brewer(type = "qual", palette = "Dark2")
    }
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
#' results <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI), id = Plot)
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
  metadata <- x$metadata
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
      select(-c(uid, all_of(metadata))) |>
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
      select(-c(uid, all_of(metadata))) |>
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
