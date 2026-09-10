test_that("failed downloads retry on the next run and successful rows resume", {
  attempts <- 0L
  local_mocked_bindings(.request_html = function(url, timeout, user_agent) {
    attempts <<- attempts + 1L
    expect_equal(timeout, 9)
    expect_equal(user_agent, "test-agent")
    if (attempts == 1L) stop("Temporary network failure")
    '<html><h1 id="course-title">Intro (CSSE1001)</h1><p id="course-prerequisite">MATH1051</p></html>'
  })
  f <- tempfile(fileext = ".csv")
  a <- fetch_course_details("CSSE1001", f, delay = 0, timeout = 9, retries = 0, academic_year = 2026, user_agent = "test-agent")
  expect_identical(a$fetch_status, "failed")
  b <- fetch_course_details("CSSE1001", f, delay = 0, timeout = 9, retries = 0, academic_year = 2026, user_agent = "test-agent")
  expect_identical(b$fetch_status, "success")
  expect_identical(b$course_name, "Intro")
  expect_match(b$source_url, "year=2026", fixed = TRUE)
  fetch_course_details("CSSE1001", f, delay = 0, timeout = 9, academic_year = 2026, user_agent = "test-agent")
  expect_equal(attempts, 2)
  fetch_course_details("CSSE1001", f, delay = 0, timeout = 9, academic_year = 2027, user_agent = "test-agent")
  expect_equal(attempts, 3)
})

test_that("transient errors retry within a run and invalid HTML is never cached as success", {
  attempts <- 0L
  local_mocked_bindings(.request_html = function(...) {
    attempts <<- attempts + 1L
    if (attempts == 1L) return('<html><h1>Service unavailable</h1></html>')
    '<h1 id="course-title">Intro (CSSE1001)</h1>'
  })
  f <- tempfile(fileext = ".csv")
  result <- fetch_course_details("CSSE1001", f, delay = 0, retries = 1)
  expect_equal(attempts, 2)
  expect_identical(result$fetch_status, "success")
  expect_equal(nrow(utils::read.csv(f)), 1)
})

test_that("partial metadata blocks downstream analysis", {
  x <- fixture_courses(); x$fetch_status <- c("success", "failed", "success")
  expect_error(parse_all_prerequisites(x, tempfile()), "Failed downloads")
  expect_error(extract_course_info(rvest::read_html('<html>No course title</html>')), "title is missing")
})
