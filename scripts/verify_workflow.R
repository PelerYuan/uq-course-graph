# Verify source entry points in an isolated workspace, without network access.
source("scripts/load_project.R")
workspace <- tempfile("uq-source-smoke-")
dir.create(workspace)
config_file <- file.path(workspace, "config.R")
writeLines(c('PROGRAM_CODE <- "DEMO"', 'PROGRAM_ROUTE_TYPE <- "plan"',
  'ACADEMIC_YEAR <- 2026',
  paste0('DATA_DIR <- ', encodeString(file.path(workspace, "data"), quote = '"')),
  paste0('OUTPUT_DIR <- ', encodeString(file.path(workspace, "output"), quote = '"'))), config_file)
config <- load_config(config_file)
import_course_data(example_file("demo_courses.csv"), config, source_label = "Synthetic smoke fixture")
withr::with_envvar(c(UQCOURSEGRAPH_CONFIG = config_file), {
  for (script in c("02_parse.R", "03_review.R", "04_build_graph.R", "05_visualize.R")) source(script)
})
paths <- project_paths(config)
stopifnot(file.exists(paths$graph), file.exists(file.path(paths$output, "course_dependency_graph.png")),
  file.exists(file.path(paths$output, "run_manifest.json")), igraph::vcount(readRDS(paths$graph)) == 4)
cat("Source workflow smoke passed. Workspace:", workspace, "\n")
