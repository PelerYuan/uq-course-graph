# Plotting reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `tag_course_status()`

Adds presentation status without changing relationships. Missing course names identify legacy external nodes. Completed and current sets cannot overlap.

```r
tag_course_status (g, completed = character(), current = character())
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `completed` | Character vector of course codes to mark completed. Must not overlap current. |
| `current` | Character vector of course codes to mark in progress. |

**Returns:** A graph with status attributes.

## `plot_course_graph()`

Renders a Sugiyama layout with relationship line styles, course status, and optional focus markers. Rejects empty selections. Parent directories are created automatically.

```r
plot_course_graph (g, output_file = "course_dependency_graph.png", title = "Course Dependency Graph",
    highlight_prefix = NULL, width = 20, height = 13, dpi = 300,
    seed = 20260910)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `output_file` | Output file path. Parent directories are created when needed. |
| `title` | Plot title. |
| `highlight_prefix` | Optional discipline prefixes to emphasize without removing other nodes. |
| `width` | Positive plot width in inches. |
| `height` | Positive plot height in inches. |
| `dpi` | Positive raster resolution in dots per inch. |
| `seed` | Non-negative integer random seed for reproducible label placement. The caller's RNG state is restored. |

**Returns:** The ggplot object invisibly; also saves the requested image.

## `plot_key_courses()`

Plots the first top_n rows of a ranking produced by rank_key_courses().

```r
plot_key_courses (key_courses_file = "key_courses.csv", top_n = 15, output_file = "stat_key_courses.png")
```

| Argument | Meaning |
| --- | --- |
| `key_courses_file` | Ranking CSV produced by rank_key_courses(), sorted by downstream reach. |
| `top_n` | Positive integer number of ranking rows to plot. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** A ggplot object invisibly; also saves a PNG.

## `plot_prefix_by_level()`

Counts supplied course rows by four-letter prefix and fifth-character code level. This level does not determine the scheduled year of study.

```r
plot_prefix_by_level (courses_file = "courses_info.csv", output_file = "stat_prefix_by_level.png")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** A ggplot object invisibly; also saves a PNG.

## `plot_prereq_count_by_level()`

Counts prerequisite edges by course level. OR alternatives are counted separately, so this is a descriptive measure, not required workload.

```r
plot_prereq_count_by_level (courses_file = "courses_info.csv", edges_file = "prereq_edges.csv",
    output_file = "stat_prereq_by_level.png")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `edges_file` | Path to a CSV containing course_code, prereq_code, and field. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** A ggplot object invisibly; also saves a PNG.

## `plot_class_hours()`

Parses weekly activity descriptions and sums their hours. Missing or unsupported descriptions are omitted.

```r
plot_class_hours (courses_file = "courses_info.csv", output_file = "stat_class_hours.png")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** A ggplot object invisibly; also saves a PNG.

## `plot_assessment_mix()`

Counts courses mentioning each assessment keyword. Categories overlap, so percentages need not sum to 100.

```r
plot_assessment_mix (courses_file = "courses_info.csv", output_file = "stat_assessment_mix.png")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** A ggplot object invisibly; also saves a PNG.
