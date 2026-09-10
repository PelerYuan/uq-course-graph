test_that("configuration validates values and separates sources", {
  a <- uq_config(data_dir = tempfile(), output_dir = tempfile())
  b <- a; b$academic_year <- 2027
  c <- a; c$program_code <- "OTHER123"
  expect_false(identical(project_paths(a)$data, project_paths(b)$data))
  expect_false(identical(project_paths(a)$data, project_paths(c)$data))
  expect_error(uq_config(program_code = "../other"))
  expect_error(uq_config(timeout = 0))
  expect_error(uq_config(retries = 0.5))
  expect_error(uq_config(completed = "CSSE1001", current = "CSSE1001"))
  f <- tempfile(fileext = ".R")
  writeLines(c('PROGRAM_CODE <- "DEMO123"', 'PROGRAM_ROUTE_TYPE <- "program"', 'ACADEMIC_YEAR <- 2027',
    'REQUEST_TIMEOUT <- 45', 'DATA_DIR <- "custom-data"', 'REQUEST_RETRIES <- 4'), f)
  cfg <- load_config(f)
  expect_equal(cfg$timeout, 45)
  expect_equal(cfg$retries, 4)
  expect_match(project_paths(cfg)$data, "custom-data/program-DEMO123-2027", fixed = TRUE)
})
