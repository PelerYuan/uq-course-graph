# Run from the repository root after installing dependencies.
source("scripts/load_project.R")

# A bundled example: no scraping, config.R, or private RDS file is needed.
courses_file <- "examples/gallery_courses.csv"
edges_file <- "examples/prereq_edges.csv"
g <- build_course_graph(courses_file, edges_file)

# Illustrative statuses, not a real student's record.
g <- tag_course_status(g,
  completed = c("CSSE1001", "MATH1051"), current = "CSSE2010")
output_dir <- "output/gallery"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20260910)
output_file <- file.path(output_dir, "04-two-levels.png")

view <- select_ancestors(g, "CSSE4010", depth = 2)
plot_course_graph(view, output_file, title = "Two levels of prerequisites",
                  width = 12, height = 8, dpi = 240)
