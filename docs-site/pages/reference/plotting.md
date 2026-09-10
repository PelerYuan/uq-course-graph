# Plotting reference

## `tag_course_status(g, completed, current)`

Adds status metadata used by the fill scale.

## `plot_course_graph(g, output_file, title, highlight_prefix, width, height, dpi)`

Renders a directed network graph and saves a PNG. `highlight_prefix` changes emphasis without removing nodes. The function returns the ggplot object invisibly so it can be further customized.

## Statistical plots

Source `R/plot_stats.R` before calling these functions. Each reads a CSV file, saves a PNG, and invisibly returns a ggplot object.

| Function | Input and parameters | Result |
| --- | --- | --- |
| `plot_key_courses(key_courses_file, top_n = 15, output_file)` | A ranking CSV from `rank_key_courses(g)`, already sorted by downstream count | Top gateway courses |
| `plot_prefix_by_level(courses_file, output_file)` | A course CSV containing `course_code` | Counts by four-character prefix and fifth-character level |
| `plot_prereq_count_by_level(courses_file, edges_file, output_file)` | Course and edge CSVs | Distribution of listed prerequisite counts; OR alternatives count separately |
| `plot_class_hours(courses_file, output_file)` | Course metadata with `class_hours` | Summed weekly hours parsed from activity descriptions |
| `plot_assessment_mix(courses_file, output_file)` | Course metadata with `assessment_methods` | Keyword-based assessment frequencies |

The [gallery](../gallery.md) includes complete runnable network, gateway-ranking, and discipline-count examples. The gallery's minimal course table does not include contact hours or assessment descriptions; use the full scraped metadata for those plots.
