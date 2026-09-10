# Run with an installed uqcoursegraph package, from any working directory.
library(uqcoursegraph)
workspace <- tempfile("uq-installed-smoke-")
dir.create(workspace)
setwd(workspace)
config <- uq_config(program_code = "DEMO", completed = "CSSE1001")
import_course_data(example_file("demo_courses.csv"), config, source_label = "Synthetic installed-package smoke fixture")
run_pipeline(config)
paths <- project_paths(config)
g <- readRDS(paths$graph)
stopifnot(igraph::vcount(g) == 4, igraph::vcount(select_ancestors(g, "CSSE4010")) == 4,
  file.exists(file.path(paths$output, "course_dependency_graph.png.manifest.json")))
cat("Installed package", as.character(packageVersion("uqcoursegraph")), "offline smoke passed.\n")
