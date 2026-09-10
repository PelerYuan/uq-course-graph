source("scripts/load_project.R")
config <- load_config()
paths <- project_paths(config)
g <- tag_course_status(readRDS(paths$graph), config$completed, config$current)
# These codes target the bundled ELECEX2350 curriculum. Adapt them to your graph.

select_courses(g, c("CSSE2002", "CSSE2310")) |>
  plot_course_graph(file.path(paths$output, "selected_courses.png"), title = "Selected courses")

select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph(file.path(paths$output, "ancestors.png"), title = "Prerequisites")

select_descendants(g, "CSSE1001") |>
  plot_course_graph(file.path(paths$output, "descendants.png"), title = "Unlocked courses")

select_neighborhood(g, "CSSE2310", depth = 2) |>
  plot_course_graph(file.path(paths$output, "neighborhood.png"),
                    highlight_prefix = c("CSSE", "ELEC"),
                    title = "Course neighborhood")

select_by_prefix(g, c("CSSE", "ELEC")) |>
  plot_course_graph(file.path(paths$output, "prefix_filter.png"), title = "Prefix filter")
