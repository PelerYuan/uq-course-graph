# Run from the repository root after installing dependencies.
source("R/build_graph.R")
source("R/visualize_graph.R")
source("R/plot_stats.R")

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
output_file <- file.path(output_dir, "11-gateways.png")

ranking_file <- file.path(output_dir, "key_courses.csv")
write.csv(rank_key_courses(g), ranking_file, row.names = FALSE)
plot_key_courses(ranking_file, top_n = 12, output_file = output_file)
