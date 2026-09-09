source(file.path("..", "..", "R", "parse_prereq.R"))

test_that("clean prerequisite expressions are recognized", {
  expect_true(is_clean_prereq("ENGG1300 and (MATH1051 or MATH1071)"))
  expect_false(is_clean_prereq("32 units completed"))
})

test_that("nested expressions produce course codes", {
  tree <- parse_prereq_expr(tokenize_prereq("ENGG1300 and (MATH1051 or MATH1071)"))
  expect_setequal(flatten_prereq_codes(tree), c("ENGG1300", "MATH1051", "MATH1071"))
})
