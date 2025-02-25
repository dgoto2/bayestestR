test_that("insight::get_predicted", {
  skip_on_os("mac")
  skip_if_not_or_load_if_installed("rstanarm")

  x <- suppressWarnings(
    insight::get_predicted(
      stan_glm(hp ~ mpg, data = mtcars, iter = 500, refresh = 0)
    )
  )

  rez <- point_estimate(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 4))

  rez <- hdi(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 4))

  rez <- eti(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 4))

  rez <- ci(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 4))

  rez <- map_estimate(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 2))

  rez <- p_direction(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 2))

  # rez <- p_map(x)
  # expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))
  #
  # rez <- p_significance(x)
  # expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))
  #
  # rez <- rope(x)
  # expect_equal(c(nrow(rez), ncol(rez)), c(2, 5))

  rez <- describe_posterior(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(32, 5))

  # rez <- estimate_density(x)
  # expect_equal(c(nrow(rez), ncol(rez)), c(2048, 3))
})

test_that("bayesQR", {
  skip_on_os("mac")
  skip_if_not_or_load_if_installed("bayesQR")

  invisible(capture.output(
    x <- bayesQR(Sepal.Length ~ Petal.Width,
      data = iris, quantile = 0.1,
      alasso = TRUE, ndraw = 500
    )
  ))

  rez <- p_direction(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))

  rez <- p_map(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))

  rez <- p_significance(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))

  rez <- rope(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 5))

  rez <- hdi(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 4))

  rez <- eti(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 4))

  rez <- map_estimate(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 2))

  rez <- point_estimate(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 4))

  rez <- describe_posterior(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2, 10))

  rez <- estimate_density(x)
  expect_equal(c(nrow(rez), ncol(rez)), c(2048, 3))
})
