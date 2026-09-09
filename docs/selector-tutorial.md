# Filtering and plotting tutorial

This tutorial assumes that the pipeline has produced `data/graph_object.rds`. It shows how to answer common planning questions with the selector API.

## Load the graph

```r
source("config.R")
source("R/visualize_graph.R")
g <- readRDS(file.path(DATA_DIR, "graph_object.rds"))
g <- tag_course_status(g, COMPLETED_COURSES, CURRENT_COURSES)
```

`tag_course_status()` adds the `status` field used by the plot legend. Valid statuses are `completed`, `current`, `future`, and `external`.

## Select specific courses

Use `select_courses()` when you want only the named nodes and edges between them:

```r
select_courses(g, c("CSSE2002", "CSSE2310")) |>
  plot_course_graph("output/two_courses.png", title = "Selected courses")
```

The function fails with a useful error if a code is absent from the graph.

## Inspect prerequisites

`select_ancestors()` follows incoming edges. `depth = 1` shows direct prerequisites; `depth = Inf` follows the chain to its roots:

```r
select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph("output/csse4010_prerequisites.png",
                    title = "Prerequisites within two levels")
```

## Inspect unlocked courses

`select_descendants()` follows outgoing edges:

```r
select_descendants(g, "CSSE1001", depth = Inf) |>
  plot_course_graph("output/csse1001_unlocks.png",
                    title = "Courses unlocked by CSSE1001")
```

## Explore a local neighborhood

`select_neighborhood()` follows both directions. A small depth is usually easier to read:

```r
select_neighborhood(g, c("CSSE2310", "ELEC2400"), depth = 2) |>
  plot_course_graph("output/local_network.png", title = "Two-level neighborhood")
```

## Filter by discipline

`select_by_prefix()` is a hard filter. It removes every node whose first four characters are not in the supplied vector, which can remove cross-discipline prerequisite edges:

```r
select_by_prefix(g, c("CSSE", "ELEC")) |>
  plot_course_graph("output/csse_elec_only.png", title = "CSSE and ELEC only")
```

Use `highlight_prefix` when you want to retain the complete graph and visually emphasize disciplines:

```r
select_neighborhood(g, "CSSE2310", depth = 2) |>
  plot_course_graph("output/csse2310_highlighted.png",
                    highlight_prefix = c("CSSE", "ELEC"),
                    title = "CSSE2310 with CSSE and ELEC highlighted")
```

## Compose selectors

Selectors return another graph, so they can be composed with the base R pipe. Apply traversal first and hard filters last:

```r
select_ancestors(g, "CSSE4010", depth = 3) |>
  select_by_prefix(c("CSSE", "MATH")) |>
  plot_course_graph("output/csse_math_prerequisites.png")
```

Remember that a hard prefix filter intentionally discards outside prefixes. Use highlighting if those relationships matter.

## Plot options

`plot_course_graph()` accepts `title`, `highlight_prefix`, `width`, `height`, and `dpi`. The returned ggplot object can be further customized before saving:

```r
p <- select_neighborhood(g, "CSSE2310", depth = 2) |>
  plot_course_graph(output_file = tempfile(fileext = ".png"),
                    title = "Draft network")
p + ggplot2::theme(legend.position = "right")
```

## Statistics

The statistics functions consume the CSV outputs rather than the graph object:

```r
source("R/plot_stats.R")
plot_key_courses("data/key_courses.csv", output_file = "output/key_courses.png")
plot_prefix_by_level("data/courses_info.csv", output_file = "output/prefix_by_level.png")
plot_prereq_count_by_level("data/courses_info.csv", "data/prereq_edges.csv",
                           output_file = "output/prereq_by_level.png")
```

See [the API reference](api-reference.md) for every public function and parameter.
