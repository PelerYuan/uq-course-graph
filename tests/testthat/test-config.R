test_that("example configuration has the required fields", {
  source(file.path("..", "..", "config.example.R"))
  expect_true(PROGRAM_ROUTE_TYPE %in% c("plan", "program"))
  expect_true(is.numeric(ACADEMIC_YEAR))
  expect_gte(REQUEST_DELAY, 0)
})
