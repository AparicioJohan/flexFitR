# Mean Absolute Error (MAE)
#' @noRd
mae <- function(actual, predicted) {
  mean(abs(actual - predicted))
}

# Mean Squared Error (MSE)
#' @noRd
mse <- function(actual, predicted) {
  mean((actual - predicted)^2)
}

# Sum Squared Error (SSE)
#' @noRd
sse <- function(actual, predicted) {
  sum((actual - predicted)^2)
}

# Root Mean Squared Error (RMSE)
#' @noRd
rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

# Coefficient of Determination (R^2)
#' @noRd
r_squared <- function(actual, predicted) {
  rss <- sum((predicted - actual)^2) # Residual sum of squares
  tss <- sum((actual - mean(actual))^2) # Total sum of squares
  1 - (rss / tss)
}

# Compute second-order AIC (AICc)
# For small sample sizes, the corrected AIC (AICc) is preferred
#' @noRd
compute_AICc <- function(object) {
  AICc_val <- object |>
    AIC.modeler() |>
    mutate(AICc = AIC + (2 * df * (df + 1)) / (nobs - df - 1))
  return(AICc_val)
}

# Merge information criteria and performance metrics
#' @noRd
info_criteria <- function(object, metrics = "all", metadata = TRUE, digits = 2) {
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  if (metadata) {
    metadata <- object$keep
  } else {
    metadata <- NULL
  }
  options_metrics <- c(
    "logLik", "AIC", "AICc", "BIC",
    "Sigma", "SSE", "MAE", "MSE", "RMSE", "R2"
  )
  if ("all" %in% metrics) {
    metrics <- options_metrics
  } else {
    metrics <- match.arg(metrics, choices = options_metrics, several.ok = TRUE)
  }
  model_fun <- object$fun
  res_metrics <- select(metrics(object), -n, -var)
  dt_metadata <- select(object$param, uid, fn_name, all_of(metadata)) |>
    unique.data.frame()
  AIC.modeler(object) |>
    mutate(AICc = AIC + (2 * df * (df + 1)) / (nobs - df - 1)) |>
    full_join(
      y = BIC.modeler(object),
      by = c("uid", "fn_name", "df", "nobs", "p", "logLik")
    ) |>
    full_join(y = dt_metadata, by = c("uid", "fn_name")) |>
    full_join(res_metrics, by = c("uid", "fn_name")) |>
    mutate(Sigma = sqrt(SSE / (nobs - p)), .after = p) |>
    relocate(logLik, .after = p) |>
    mutate_if(is.numeric, round, digits) |>
    select(fn_name, uid, df, nobs, p, all_of(metadata), all_of(metrics))
}

#' @title Compare performance of different models
#' @description
#' Computes indices of model performance for different models at once and hence
#' allows comparison of indices across models.
#' @param ... Multiple model objects (only of class `modeler`).
#' @param metrics Can be "all" or a character vector of metrics to be computed
#' (one or more of "logLik", "AIC", "AICc", "BIC", "Sigma", "SSE", "MAE", "MSE", "RMSE", "R2").
#' "AICc" by default.
#' @param metadata Logical. If \code{TRUE}, metadata is included with the
#' performance metrics. Default is \code{FALSE}.
#' @param digits An integer. The number of decimal places to round the output. Default is 2.
#' @return A data.frame with performance metrics for models in (...).
#' @export
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' # Model 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 90),
#'     subset = 40
#'   )
#' print(mod_1)
#' # Model 2
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(a = 0.199, t0 = 47.7, k = 100),
#'     subset = 40
#'   )
#' print(mod_2)
#' # Model 3
#' mod_3 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin",
#'     parameters = c(m = 20, b = 2),
#'     subset = 40
#'   )
#' print(mod_3)
#' performance(mod_1, mod_2, mod_3, metrics = c("AIC", "AICc", "BIC", "Sigma"))
performance <- function(..., metrics = "AICc", metadata = FALSE, digits = 2) {
  .arguments <- list(...)
  .lf <- length(.arguments)
  if (.lf == 0) stop("You must provide a model")
  .evaluation <- lapply(.arguments, info_criteria, metrics, metadata, digits)
  for (i in 1:.lf) {
    .evaluation[[i]]$fn_name <- paste0(.evaluation[[i]]$fn_name, "_", i)
  }
  .out <- do.call(what = rbind, args = .evaluation) |>
    arrange(uid, fn_name)
  class(.out) <- c("performance", class(.out))
  return(.out)
}

#' Plot an object of class \code{performance}
#'
#' @description Creates plots for an object of class \code{performance}
#' @aliases plot.performance
#' @param x An object of class \code{performance}, typically the result of calling \code{performance()}.
#' @param id An optional group ID to filter the data for plotting, useful for avoiding overcrowded plots.
#' This argument is not used when type = 2.
#' @param type Numeric value (1-3) to specify the type of plot to generate. Default is 1.
#' \describe{
#'   \item{\code{type = 1}}{Radar plot by uid}
#'   \item{\code{type = 2}}{Radar plot averaging}
#'   \item{\code{type = 3}}{Line plot by model-metric}
#'   \item{\code{type = 4}}{Ranking plot by model}
#' }
#' @param rescale Logical. If \code{TRUE}, metrics in type 3 plot are (0, 1) rescaled to improve interpretation.
#' Higher values are better models. \code{FALSE} by default.
#' @param linewidth Numeric value specifying size of line geoms.
#' @param base_size Numeric value for the base font size in pts. Default is 12
#' @param return_table Logical. If \code{TRUE}, table to generate the plot is
#' returned. \code{FALSE} by default.
#' @param ... Additional graphical parameters for future extensions.
#' @author Johan Aparicio [aut]
#' @method plot performance
#' @return A \code{ggplot} object representing the specified plot.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' # Model 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 90),
#'     subset = 40
#'   )
#' # Model 2
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(a = 0.199, t0 = 47.7, k = 100),
#'     subset = 40
#'   )
#' # Model 3
#' mod_3 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin",
#'     parameters = c(m = 20, b = 2),
#'     subset = 40
#'   )
#' plot(performance(mod_1, mod_2, mod_3), metrics = "all", type = 1)
#' plot(performance(mod_1, mod_2, mod_3, metrics = c("AICc", "BIC")), type = 3)
#' @import ggplot2
#' @import dplyr
plot.performance <- function(x,
                             id = NULL,
                             type = 1,
                             rescale = FALSE,
                             linewidth = 1,
                             base_size = 12,
                             return_table = FALSE, ...) {
  coord_radar <- function(theta = "x", start = 0, direction = 1, ...) {
    theta <- match.arg(theta, c("x", "y"))
    r <- ifelse(theta == "x", "y", "x")
    ggplot2::ggproto(
      "CordRadar",
      CoordPolar,
      theta = theta,
      r = r,
      start = start,
      direction = sign(direction),
      is_linear = function(coord) {
        TRUE
      },
      ...
    )
  }
  .data_performance <- x
  .num_models <- length(unique(.data_performance$fn_name))
  if (.num_models == 1) stop("You must have several models.")
  if (is.null(id)) {
    id <- .data_performance$uid[1]
  } else {
    if (!all(id %in% unique(.data_performance$uid))) {
      stop("ids not found in x.")
    }
  }
  if (type == 2) id <- unique(.data_performance$uid)
  .data_performance <- droplevels(filter(.data_performance, uid %in% id))
  .positive <- c("AIC", "AICc", "BIC", "Sigma", "SSE", "MAE", "MSE", "RMSE")
  .negative <- c("logLik", "R2")
  .list <- c(.positive, .negative)
  .slt <- names(.data_performance)[names(.data_performance) %in% .list]
  n_min <- 0.1
  n_max <- 1
  .data <- .data_performance |>
    select(fn_name, uid, any_of(.slt)) |>
    pivot_longer(cols = any_of(.slt), names_to = "name") |>
    filter(!is.infinite(value)) |> # Check
    filter(!is.na(value)) |> # Check
    group_by(uid, name) |>
    mutate(
      o_min = min(value, na.rm = TRUE),
      o_max = max(value, na.rm = TRUE),
      res = (value - o_min) / (o_max - o_min) * (n_max - n_min) + n_min
    ) |>
    mutate(res = ifelse(name %in% .positive, 1.1 - res, res)) |>
    mutate(fn_name = as.factor(fn_name), name = factor(name, levels = .slt))
  if (nrow(.data) == 0) stop("The models being compared are identical.")
  if (type == 1) {
    p <- .data |>
      ggplot(
        mapping = aes(
          x = name,
          y = res,
          colour = fn_name,
          group = fn_name,
          fill = fn_name
        )
      ) +
      geom_polygon(linewidth = linewidth, alpha = 0.1) +
      coord_radar() +
      scale_y_continuous(limits = c(0, 1), labels = NULL) +
      guides(fill = "none") +
      theme_minimal(base_size = base_size) +
      scale_color_brewer(type = "qual", palette = "Dark2") +
      scale_fill_brewer(type = "qual", palette = "Dark2") +
      labs(x = NULL, y = NULL, color = "Model") +
      facet_wrap(~uid, labeller = label_both)
  }
  if (type == 2) {
    .data <- .data |>
      group_by(fn_name, name) |>
      summarise(res = mean(res, na.rm = TRUE), .groups = "drop")
    p <- .data |>
      ggplot(
        mapping = aes(
          x = name,
          y = res,
          colour = fn_name,
          group = fn_name,
          fill = fn_name
        )
      ) +
      geom_polygon(linewidth = linewidth, alpha = 0.1) +
      coord_radar() +
      scale_y_continuous(limits = c(0, 1), labels = NULL) +
      guides(fill = "none") +
      theme_minimal(base_size = base_size) +
      scale_color_brewer(type = "qual", palette = "Dark2") +
      scale_fill_brewer(type = "qual", palette = "Dark2") +
      labs(x = NULL, y = NULL, color = "Model")
  }
  if (type == 3) {
    var_plot <- ifelse(rescale, "res", "value")
    p <- .data |>
      ggplot(
        mapping = aes(
          x = fn_name,
          y = .data[[var_plot]],
          group = uid,
          color = as.factor(uid)
        )
      ) +
      geom_line(alpha = 0.6) +
      geom_point(alpha = 0.2) +
      facet_wrap(~name, scales = "free") +
      theme_classic(base_size = base_size) +
      labs(y = NULL, x = NULL, color = "uid") +
      theme(axis.text.x = element_text(hjust = 1, angle = 75)) +
      scale_color_viridis_d(option = "D", direction = 1)
  }
  if (type == 4) {
    p <- .data |>
      group_by(uid, fn_name) |>
      summarise(k = mean(res), .groups = "drop") |>
      ungroup() |>
      group_by(uid) |>
      mutate(rank = rank(-k)) |>
      group_by(fn_name, rank) |>
      summarise(freq = n(), .groups = "drop") |>
      group_by(fn_name) |>
      mutate(freq = freq / sum(freq) * 100) |>
      ggplot(aes(x = rank, y = freq, fill = fn_name)) +
      geom_bar(stat = "identity", alpha = 0.5, color = "black") +
      theme_classic() +
      scale_color_brewer(type = "qual", palette = "Dark2") +
      scale_fill_brewer(type = "qual", palette = "Dark2") +
      geom_text(
        mapping = aes(label = round(freq, 1)),
        position = position_stack(vjust = 0.5)
      ) +
      labs(y = "Frequency (%)", fill = "Model", x = "Rank")
  }
  if (return_table) {
    return(.data)
  } else {
    return(p)
  }
}

#' Metrics for an object of class \code{modeler}
#'
#' Computes various performance metrics for a modeler object.
#' The function calculates Sum of Squared Errors (SSE), Mean Absolute Error (MAE),
#' Mean Squared Error (MSE), Root Mean Squared Error (RMSE), and the Coefficient
#' of Determination (R-squared).
#'
#' @param x An object of class `modeler` containing the necessary data to compute the metrics.
#' @param by_grp Return the metrics by id? TRUE by default.
#'
#' @return A data frame containing the calculated metrics grouped by uid, metadata, and variables.
#'
#' @details
#' \if{html}{
#' Sum of Squared Errors (SSE):
#' \deqn{SSE = \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
#'
#' Mean Absolute Error (MAE):
#' \deqn{MAE = \frac{1}{n} \sum_{i=1}^{n} |y_i - \hat{y}_i|}
#'
#' Mean Squared Error (MSE):
#' \deqn{MSE = \frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
#'
#' Root Mean Squared Error (RMSE):
#' \deqn{RMSE = \sqrt{\frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}}
#'
#' Coefficient of Determination (R-squared):
#' \deqn{R^2 = 1 - \frac{\sum_{i=1}^{n} (y_i - \hat{y}_i)^2}{\sum_{i=1}^{n} (y_i - \bar{y})^2}}
#' }
#'
#' @export
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(1:2)
#'   )
#' plot(mod_1, id = c(1:2))
#' print(mod_1)
#' metrics(mod_1)
metrics <- function(x, by_grp = TRUE) {
  if (!inherits(x, "modeler")) {
    stop("The object should be of modeler class")
  }
  val_metrics <- x$dt |>
    group_by(uid, fn_name, var) |>
    summarise(
      SSE = sse(y, .fitted),
      MAE = mae(y, .fitted),
      MSE = mse(y, .fitted),
      RMSE = sqrt(MSE),
      R2 = r_squared(y, .fitted),
      n = n(),
      .groups = "drop"
    )
  n_plots <- nrow(val_metrics)
  if (!by_grp && n_plots > 1) {
    summ_metrics <- val_metrics |>
      select(var:R2) |>
      pivot_longer(cols = SSE:R2, names_to = "metric") |>
      group_by(var, metric) |>
      summarise(
        Min = suppressWarnings(min(value, na.rm = TRUE)),
        Mean = mean(value, na.rm = TRUE),
        Median = median(value, na.rm = TRUE),
        Max = suppressWarnings(max(value, na.rm = TRUE)),
        SD = sd(value, na.rm = TRUE),
        CV = SD / Mean,
        .groups = "drop"
      )
    return(summ_metrics)
  } else {
    return(val_metrics)
  }
}


#' @title Select the best model for each group
#' @description
#' Compares two or more fitted \code{modeler} objects and selects the preferred
#' model separately for each group (\code{uid}). Candidate models are ranked
#' using one or more model-performance metrics.
#'
#' @param ... Two or more model objects (only of class \code{modeler}), fitted
#' on the same groups.
#'
#' @param metrics Character vector specifying the metrics used for model
#' selection. Available options are \code{"logLik"}, \code{"AIC"},
#' \code{"AICc"}, \code{"BIC"}, \code{"Sigma"}, \code{"SSE"}, \code{"MAE"},
#' \code{"MSE"}, \code{"RMSE"}, and \code{"R2"}. Use \code{"all"} to include
#' all available metrics. The default is \code{"AICc"}.
#' @param return_table Logical. If \code{TRUE}, the selection table is returned
#' instead of the combined \code{modeler} object. \code{FALSE} by default.
#' @return A \code{modeler} object holding the winning fit for each group. Two
#' attributes are attached: \code{"selection"} (the winner, its score and the
#' number of metrics used, per group) and \code{"performance"} (the full
#' comparison table, of class \code{performance}, ready for
#' \code{plot()}).
#' @details
#' Model selection is performed independently within each group. For each
#' metric, candidate models are min-max rescaled to a range from 0.1 to 1.
#' Metrics for which smaller values indicate better performance
#' (\code{AIC}, \code{AICc}, \code{BIC}, \code{Sigma}, \code{SSE},
#' \code{MAE}, \code{MSE}, and \code{RMSE}) are reversed after rescaling,
#' whereas \code{logLik} and \code{R2} retain their original direction.
#' Higher rescaled values therefore always indicate better performance.
#'
#' Several available metrics contain overlapping information. For example,
#' \code{SSE}, \code{MSE}, \code{RMSE}, and \code{R2} produce equivalent
#' rankings within a group, while \code{AIC}, \code{AICc}, and \code{BIC}
#' are all likelihood-based criteria that differ in how model complexity is
#' penalized. Consequently, \code{metrics = "all"} should not be interpreted
#' as combining independent measures of model performance. When multiple
#' metrics are used, an explicit subset should be chosen according to the
#' objective of the analysis.
#' @seealso
#' \code{\link{performance}}, \code{\link{modeler}}
#'
#' @author Johan Aparicio [aut]
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 90),
#'     subset = c(1, 7)
#'   )
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(a = 0.199, t0 = 47.7, k = 100),
#'     subset = c(1, 7)
#'   )
#' best <- model_selection(mod_1, mod_2, metrics = "AIC")
#' print(best)
#' attr(best, "selection")
#' plot(best, id = c(1, 7))
#' @import dplyr
model_selection <- function(..., metrics = "AICc", return_table = FALSE) {
  .arguments <- list(...)
  .lf <- length(.arguments)
  if (.lf <= 1) {
    stop("You must provide at least two models to compare.", call. = FALSE)
  }
  .is_modeler <- vapply(.arguments, inherits, logical(1), what = "modeler")
  if (!all(.is_modeler)) {
    stop(
      "Objects passed in `...` must be of class 'modeler'. Check argument(s): ",
      paste(which(!.is_modeler), collapse = ", "),
      call. = FALSE
    )
  }
  # Direction of each metric
  .lower_better <- c("AIC", "AICc", "BIC", "Sigma", "SSE", "MAE", "MSE", "RMSE")
  .higher_better <- c("logLik", "R2")
  # Only groups fitted by every model can be compared
  .ids <- lapply(.arguments, \(x) unique(x$param$uid))
  .common <- Reduce(intersect, .ids)
  if (length(.common) == 0) {
    stop("The models provided have no groups (uid) in common.", call. = FALSE)
  }
  .dropped <- setdiff(Reduce(union, .ids), .common)
  if (length(.dropped) > 0) {
    warning(
      "Only groups fitted by every model are compared. ",
      length(.dropped), " group(s) dropped: ",
      paste(head(.dropped, 5), collapse = ", "),
      ifelse(length(.dropped) > 5, ", ...", ""),
      call. = FALSE
    )
  }
  .evaluation <- lapply(
    X = .arguments,
    FUN = \(x) {
      info_criteria(
        object = subset(x, id = .common),
        metrics = metrics,
        metadata = FALSE,
        digits = 15
      )
    }
  )
  for (i in seq_len(.lf)) {
    .evaluation[[i]]$model <- .evaluation[[i]]$fn_name
    .evaluation[[i]]$fn_name <- paste0(.evaluation[[i]]$fn_name, "_", i)
    .evaluation[[i]]$order <- i
  }
  .out <- bind_rows(.evaluation) |> arrange(uid, fn_name)
  .meta <- .out |>
    select(uid, fn_name, model, order) |>
    unique.data.frame()
  .slt <- names(.out)[names(.out) %in% c(.lower_better, .higher_better)]
  if (length(.slt) == 0) {
    stop("None of the requested metrics could be computed.", call. = FALSE)
  }
  n_min <- 0.1
  n_max <- 1
  .scores <- .out |>
    select(fn_name, uid, any_of(.slt)) |>
    tidyr::pivot_longer(cols = any_of(.slt), names_to = "name") |>
    group_by(uid, name) |>
    filter(all(is.finite(value))) |>
    mutate(
      o_min = min(value),
      o_max = max(value),
      res = (value - o_min) / (o_max - o_min) * (n_max - n_min) + n_min,
      res = ifelse(name %in% .lower_better, n_min + n_max - res, res),
      res = ifelse(o_max > o_min, res, n_max)
    ) |>
    ungroup() |>
    mutate(fn_name = as.factor(fn_name), name = factor(name, levels = .slt))
  .index <- .scores |>
    group_by(uid, fn_name) |>
    summarise(score = mean(res), n_metrics = n(), .groups = "drop") |>
    left_join(.meta, by = join_by(uid, fn_name)) |>
    arrange(uid, order) |>
    group_by(uid) |>
    slice_max(score, n = 1, with_ties = FALSE) |>
    ungroup()
  .no_metric <- setdiff(.common, unique(.index$uid))
  if (length(.no_metric) > 0) {
    warning(
      "No usable metric for ", length(.no_metric), " group(s): ",
      paste(head(.no_metric, 5), collapse = ", "),
      ifelse(length(.no_metric) > 5, ", ...", ""),
      ". They are not present in the output.",
      call. = FALSE
    )
  }
  if (return_table) {
    return(.index)
  }
  .selected <- split(x = .index$uid, f = .index$order)
  .models <- lapply(
    X = names(.selected),
    FUN = \(k) subset(.arguments[[as.numeric(k)]], id = .selected[[k]])
  )
  .best <- do.call(what = c, args = .models)
  .ord <- as.character(.index$uid)
  .pos <- order(match(vapply(.best$fit, \(z) as.character(z$uid), ""), .ord))
  .best$fit <- .best$fit[.pos]
  .best$param <- arrange(.best$param, match(as.character(uid), .ord))
  .best$dt <- arrange(.best$dt, match(as.character(uid), .ord))
  .best$metrics <- arrange(.best$metrics, match(as.character(uid), .ord))
  class(.out) <- c("performance", class(.out))
  attr(.best, "selection") <- .index
  attr(.best, "performance") <- .out
  return(.best)
}
