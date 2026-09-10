test_that("review pauses the pipeline, preserves edits, and applies changes idempotently", {
  w <- fixture_workspace()
  expect_error(run_pipeline(w$config), "paused for manual review")
  template <- utils::read.csv(w$paths$template, stringsAsFactors = FALSE)
  expect_equal(nrow(template), 1)
  template$status <- "approved"
  template$cleaned_text <- "CSSE2010"
  template$note <- "Synthetic fixture: course component approved for test only."
  utils::write.csv(template, w$paths$template, row.names = FALSE)
  run_stage("review", w$config)
  first <- readLines(w$paths$edges)
  run_stage("review", w$config)
  expect_identical(readLines(w$paths$edges), first)
  expect_identical(utils::read.csv(w$paths$template)$note, template$note)
  g <- run_stage("graph", w$config)
  expect_equal(igraph::vcount(g), 3)
  expect_equal(igraph::ecount(g), 3)
  expect_equal(igraph::vcount(select_ancestors(g, "CSSE2310")), 3)
  expect_equal(igraph::vcount(select_descendants(g, "CSSE1001")), 3)
  plot <- run_stage("plot", w$config)
  expect_s3_class(plot, "ggplot")
  png <- file.path(w$paths$output, "course_dependency_graph.png")
  expect_true(file.exists(png))
  expect_true(file.exists(paste0(png, ".manifest.json")))
  manifest <- jsonlite::read_json(file.path(w$paths$output, "run_manifest.json"))
  expect_identical(manifest$source_id, "plan-DEMO123-2026")
  expect_identical(manifest$stages$plot$outputs[[1]]$sha256, digest::digest(file = png, algo = "sha256"))
  expect_true(file.exists(file.path(w$paths$data, "sessionInfo.txt")))
  # A template edit must invalidate the previously reviewed graph inputs.
  template$note <- "Changed after graph generation"
  utils::write.csv(template, w$paths$template, row.names = FALSE)
  expect_error(run_stage("graph", w$config), "Stale review")
})

test_that("changed source text resets approval and archives prior work", {
  w <- fixture_workspace()
  run_stage("parse", w$config); run_stage("review", w$config)
  t <- utils::read.csv(w$paths$template, stringsAsFactors = FALSE)
  t$status <- "special"; t$note <- "Requires academic advice."
  utils::write.csv(t, w$paths$template, row.names = FALSE)
  run_stage("review", w$config)
  expect_equal(nrow(utils::read.csv(w$paths$special)), 1)
  courses <- fixture_courses(); courses$prerequisite[3] <- "48 units and CSSE2010"
  utils::write.csv(courses, w$paths$courses, row.names = FALSE)
  expect_error(run_stage("graph", w$config), "Stale parse")
  replacement <- file.path(w$root, "replacement.csv")
  utils::write.csv(courses, replacement, row.names = FALSE)
  import_course_data(replacement, w$config, overwrite = TRUE)
  run_stage("parse", w$config)
  expect_error(apply_manual_overrides(w$paths$template, w$paths$edges, w$paths$logic, w$paths$special, w$paths$review), "stale")
  result <- run_stage("review", w$config)
  expect_identical(result$status, "pending")
  expect_identical(utils::read.csv(w$paths$template)$status, "pending")
  archived <- sub(".csv", "_archive.csv", w$paths$template, fixed = TRUE)
  expect_identical(utils::read.csv(archived)$note, t$note)
})

test_that("invalid approvals leave prior results untouched and special decisions remove old edges", {
  w <- fixture_workspace(); run_stage("parse", w$config); run_stage("review", w$config)
  t <- utils::read.csv(w$paths$template, stringsAsFactors = FALSE)
  t$status <- "approved"; t$cleaned_text <- "CSSE2010 and"
  utils::write.csv(t, w$paths$template, row.names = FALSE)
  before <- readLines(w$paths$edges)
  expect_error(run_stage("review", w$config), "Invalid approved")
  expect_identical(readLines(w$paths$edges), before)
  t$cleaned_text <- "CSSE2010"; utils::write.csv(t, w$paths$template, row.names = FALSE)
  run_stage("review", w$config)
  t$status <- "special"; t$note <- "Non-course condition retained."
  utils::write.csv(t, w$paths$template, row.names = FALSE)
  run_stage("review", w$config)
  e <- utils::read.csv(w$paths$edges)
  expect_false(any(e$course_code == "CSSE2310" & e$field == "prerequisite"))
})

test_that("a course with no prerequisites completes every offline stage", {
  x <- fixture_courses()[1, , drop = FALSE]
  w <- fixture_workspace(x)
  expect_no_error(run_pipeline(w$config))
  expect_equal(igraph::ecount(readRDS(w$paths$graph)), 0)
  expect_equal(nrow(utils::read.csv(w$paths$special)), 0)
})
