#' @title Find Default Equivalence (ROPE) Region Bounds
#'
#' @description This function attempts at automatically finding suitable "default"
#'   values for the Region Of Practical Equivalence (ROPE).
#'
#' @details \cite{Kruschke (2018)} suggests that the region of practical
#'   equivalence could be set, by default, to a range from `-0.1` to
#'   `0.1` of a standardized parameter (negligible effect size
#'   according to Cohen, 1988).
#'
#'   \itemize{
#'     \item For **linear models (lm)**, this can be generalised to
#'     \ifelse{html}{\out{-0.1 * SD<sub>y</sub>, 0.1 *
#'     SD<sub>y</sub>}}{\eqn{[-0.1*SD_{y}, 0.1*SD_{y}]}}.
#'
#'     \item For **logistic models**, the parameters expressed in log odds
#'     ratio can be converted to standardized difference through the formula
#'     \ifelse{html}{\out{&pi;/&radic;(3)}}{\eqn{\pi/\sqrt{3}}}, resulting in a
#'     range of `-0.18` to `0.18`.
#'
#'     \item For other models with **binary outcome**, it is strongly
#'     recommended to manually specify the rope argument. Currently, the same
#'     default is applied that for logistic models.
#'
#'     \item For models from **count data**, the residual variance is used.
#'     This is a rather experimental threshold and is probably often similar to
#'     `-0.1, 0.1`, but should be used with care!
#'
#'     \item For **t-tests**, the standard deviation of the response is
#'     used, similarly to linear models (see above).
#'
#'     \item For **correlations**, `-0.05, 0.05` is used, i.e., half
#'     the value of a negligible correlation as suggested by Cohen's (1988)
#'     rules of thumb.
#'
#'     \item For all other models, `-0.1, 0.1` is used to determine the
#'     ROPE limits, but it is strongly advised to specify it manually.
#'   }
#'
#' @param x A `stanreg`, `brmsfit` or `BFBayesFactor` object.
#' @param verbose Toggle warnings.
#' @inheritParams rope
#'
#' @examples
#' \dontrun{
#' if (require("rstanarm")) {
#'   model <- suppressWarnings(stan_glm(
#'     mpg ~ wt + gear,
#'     data = mtcars,
#'     chains = 2,
#'     iter = 200,
#'     refresh = 0
#'   ))
#'   rope_range(model)
#'
#'   model <- suppressWarnings(
#'     stan_glm(vs ~ mpg, data = mtcars, family = "binomial", refresh = 0)
#'   )
#'   rope_range(model)
#' }
#'
#' if (require("brms")) {
#'   model <- brm(mpg ~ wt + cyl, data = mtcars)
#'   rope_range(model)
#' }
#'
#' if (require("BayesFactor")) {
#'   model <- ttestBF(mtcars[mtcars$vs == 1, "mpg"], mtcars[mtcars$vs == 0, "mpg"])
#'   rope_range(model)
#'
#'   model <- lmBF(mpg ~ vs, data = mtcars)
#'   rope_range(model)
#' }
#' }
#'
#' @references Kruschke, J. K. (2018). Rejecting or accepting parameter values
#'   in Bayesian estimation. Advances in Methods and Practices in Psychological
#'   Science, 1(2), 270-280. \doi{10.1177/2515245918771304}.
#'
#' @export
rope_range <- function(x, ...) {
  UseMethod("rope_range")
}


#' @rdname rope_range
#' @export
rope_range.default <- function(x, verbose = TRUE, ...) {
  response <- insight::get_response(x, source = "mf")
  response_transform <- insight::find_transformation(x)
  information <- insight::model_info(x, verbose = FALSE)

  if (insight::is_multivariate(x)) {
    ret <- Map(
      function(i, j, ...) .rope_range(x, i, j), information, response, response_transform, verbose
    )
    return(ret)
  } else {
    .rope_range(x, information, response, response_transform, verbose)
  }
}


#' @export
rope_range.data.frame <- function(x, verbose = TRUE, ...) {
  # to avoid errors with "get_response()" in the default method
  c(-0.1, 0.1)
}


# Exceptions --------------------------------------------------------------

#' @export
rope_range.mlm <- function(x, verbose = TRUE, ...) {
  response <- insight::get_response(x, source = "mf")
  information <- insight::model_info(x, verbose = FALSE)

  lapply(response, function(i) .rope_range(x, information, i, response_transform = NULL, verbose))
}



# helper ------------------


.rope_range <- function(x, information = NULL, response = NULL, response_transform = NULL, verbose = TRUE) {
  negligible_value <- tryCatch(
    {
      if (!is.null(response_transform) && grepl("log", response_transform, fixed = TRUE)) {
        # for log-transform, we assume that a 1% change represents the ROPE adequately
        # see https://github.com/easystats/bayestestR/issues/487
        0.01
      } else if (information$is_linear && information$link_function == "log") {
        # for log-transform, we assume that a 1% change represents the ROPE adequately
        # see https://github.com/easystats/bayestestR/issues/487
        0.01
      } else if (information$family == "lognormal") {
        # for log-transform, we assume that a 1% change represents the ROPE adequately
        # see https://github.com/easystats/bayestestR/issues/487
        0.01
      } else if (!is.null(response) && information$link_function == "identity") {
        # Linear Models
        0.1 * stats::sd(response, na.rm = TRUE)
        # 0.1 * stats::sigma(x) # https://github.com/easystats/bayestestR/issues/364
      } else if (information$is_logit) {
        # Logistic Models (any)
        # Sigma==pi / sqrt(3)
        0.1 * pi / sqrt(3)
      } else if (information$is_probit) {
        # Probit models
        # Sigma==1
        0.1 * 1
      } else if (information$is_correlation) {
        # Correlations
        # https://github.com/easystats/bayestestR/issues/121
        0.05
      } else if (information$is_count) {
        # Not sure about this
        sig <- stats::sigma(x)
        if (is.null(sig) || length(sig) == 0 || is.na(sig)) stop()
        0.1 * sig
      } else {
        # Default
        stop()
      }
    },
    error = function(e) {
      if (isTRUE(verbose)) {
        insight::format_warning("Could not estimate a good default ROPE range. Using 'c(-0.1, 0.1)'.")
      }
      0.1
    }
  )

  c(-1, 1) * negligible_value
}
