fixture_courses <- function() data.frame(
  course_code = c("CSSE1001", "CSSE2010", "CSSE2310"),
  course_name = c("Intro", "Intermediate", "Advanced"),
  prerequisite = c(NA, "CSSE1001", "32 units and CSSE2010"),
  recommended_prerequisite = c(NA, NA, "CSSE1001"))

fixture_workspace <- function(courses = fixture_courses()) {
  root <- tempfile("uq-test-"); dir.create(root)
  cfg <- uq_config("DEMO123", 2026, data_dir = file.path(root, "inputs"), output_dir = file.path(root, "figures"))
  input <- file.path(root, "source.csv")
  utils::write.csv(courses, input, row.names = FALSE)
  import_course_data(input, cfg, source_label = "Synthetic test fixture")
  list(root = root, config = cfg, paths = project_paths(cfg))
}
