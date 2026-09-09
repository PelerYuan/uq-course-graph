source("config.R")
source("R/visualize_graph.R")

g <- readRDS(file.path(DATA_DIR, "graph_object.rds"))
g <- tag_course_status(g, COMPLETED_COURSES, CURRENT_COURSES)

select_courses(g, c("CSSE2002", "CSSE2310")) |>
  plot_course_graph(file.path(OUTPUT_DIR, "selected_courses.png"), title = "Selected courses")

select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph(file.path(OUTPUT_DIR, "ancestors.png"), title = "Prerequisites")

select_descendants(g, "CSSE1001") |>
  plot_course_graph(file.path(OUTPUT_DIR, "descendants.png"), title = "Unlocked courses")

select_neighborhood(g, "CSSE2310", depth = 2) |>
  plot_course_graph(file.path(OUTPUT_DIR, "neighborhood.png"),
                    highlight_prefix = c("CSSE", "ELEC"),
                    title = "Course neighborhood")

select_by_prefix(g, c("CSSE", "ELEC")) |>
  plot_course_graph(file.path(OUTPUT_DIR, "prefix_filter.png"), title = "Prefix filter")
