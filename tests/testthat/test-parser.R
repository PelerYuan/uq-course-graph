test_that("Boolean precedence is preserved and malformed syntax is rejected", {
  tree <- parse_prereq_expr(tokenize_prereq("CSSE1001 or MATH1051 and MATH1071"))
  expect_identical(tree$op, "or")
  expect_identical(tree$args[[2]]$op, "and")
  expect_setequal(flatten_prereq_codes(tree), c("CSSE1001", "MATH1051", "MATH1071"))
  for (text in c("CSSE1001 and", "and", "()", "(CSSE1001", "CSSE1001)", "CSSE1001 MATH1051", "CSSE1001 or or MATH1051"))
    expect_error(parse_prereq_expr(tokenize_prereq(text)))
  expect_error(tokenize_prereq("CSSE1001, MATH1051"), "Ambiguous comma")
  expect_setequal(flatten_prereq_codes(parse_prereq_expr(tokenize_prereq("CSSE1001, or MATH1051."))), c("CSSE1001", "MATH1051"))
  expect_error(tokenize_prereq("32 units including CSSE1001"), "manual review")
  expect_error(flatten_prereq_codes(list(op = "and", args = list("CSSE1001", NULL))))
})

test_that("empty tables preserve their schemas and invalid input reaches review", {
  d <- tempfile(); dir.create(d)
  courses <- data.frame(course_code = c("CSSE1001", "CSSE2010"), course_name = c("Intro", "Next"),
    prerequisite = c(NA, "CSSE1001 and"), recommended_prerequisite = NA_character_)
  result <- parse_all_prerequisites(courses, d)
  expect_equal(nrow(result$manual_review), 1)
  expect_equal(nrow(result$edges), 0)
  expect_named(utils::read.csv(file.path(d, "prereq_edges.csv")), c("course_code", "prereq_code", "field"))
  expect_equal(nrow(build_course_graph({f <- file.path(d, "courses.csv"); utils::write.csv(courses, f, row.names = FALSE); f}, file.path(d, "prereq_edges.csv")) |> tidygraph::activate(nodes) |> tibble::as_tibble()), 2)
})
