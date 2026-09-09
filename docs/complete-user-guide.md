# Complete user guide

This guide is written for a new R user who has never seen this repository. It explains the whole workflow, the files created at each stage, and the decisions behind every graph selector. The examples use the captured sample data when possible, so the analytical stages can be practiced without making network requests.

## 1. What the project produces

The project models a UQ curriculum as a directed graph. Each node is a course code. An edge points from a course to one of its prerequisites. For example, an edge from `CSSE2310` to `CSSE2010` means that `CSSE2010` is listed as a prerequisite or recommended prerequisite for `CSSE2310`.

The workflow has five stages:

1. Scrape a plan or program page and its course pages.
2. Parse prerequisite text into edge rows and Boolean logic trees.
3. Review expressions that contain free text or academic rules.
4. Build and validate a graph.
5. Select a useful subgraph and render it as a figure.

The scraper is the only network-dependent stage. The other stages consume files in `data/` and can be repeated offline.

## 2. Install the environment

Install R 4.1 or newer and Google Chrome. Chrome is required because UQ requirements pages render course lists with JavaScript and `chromote` controls a local headless Chrome session.

From the repository root, install the packages:

```r
source("install_deps.R")
```

The installer checks which packages are missing before calling `install.packages()`. If an installation fails, rerun the command after resolving the R package or system dependency reported by R.

## 3. Configure a real UQ plan

Copy the template once:

```powershell
Copy-Item config.example.R config.R
```

Open `config.R` and set:

```r
PROGRAM_CODE <- "ELECEX2350"
PROGRAM_ROUTE_TYPE <- "plan"
ACADEMIC_YEAR <- 2026
COMPLETED_COURSES <- c("MATH1051")
CURRENT_COURSES <- c("CSSE2310")
REQUEST_DELAY <- 1
REQUEST_TIMEOUT <- 30
```

`PROGRAM_CODE` is the code in the UQ requirements URL. A plan URL looks like `/requirements/plan/CODE/YEAR`; a program URL looks like `/requirements/program/CODE/YEAR`. Set `PROGRAM_ROUTE_TYPE` to the matching word.

`COMPLETED_COURSES` and `CURRENT_COURSES` only affect colors and legends in plots. They do not change the graph structure. Course codes must be uppercase and must exist in the graph, otherwise the visualization stage reports the missing code.

## 4. Run the scraping stage

Run:

```r
source("01_scrape.R")
```

The stage builds a URL from the three program settings, opens it with Chrome, extracts rendered `.curriculum-reference__code` elements, and writes `data/course_codes.csv`. It then requests one static course page per code and writes `data/courses_info.csv`.

The course detail request uses a browser-like User-Agent, a timeout, and a delay between requests. Existing course codes in the output file are skipped, so rerunning the stage is safe and avoids unnecessary requests.

Check the console for:

```text
Extracted 61 records
[1/61] CSSE1001: success
...
Saved to data/courses_info.csv
```

If the rendered page contains no course codes, the stage stops instead of writing an empty dataset. Check the route, code, year, Chrome installation, and the UQ page in a normal browser.

## 5. Understand the course table

`data/courses_info.csv` contains one row per course. The first column is `course_code`. Other columns contain the course name, level, faculty, school, units, duration, contact hours, incompatibilities, prerequisite text, recommended prerequisite text, and assessment methods.

Before parsing, inspect the table:

```r
courses <- read.csv("data/courses_info.csv", stringsAsFactors = FALSE)
str(courses)
summary(courses)
colSums(is.na(courses))
```

A high missing-value count can be normal for optional fields. A zero-row table or missing `course_code` column indicates that scraping did not complete successfully.

## 6. Parse prerequisite expressions

Run:

```r
source("02_parse.R")
```

The parser recognizes course-code Boolean expressions such as:

```text
ENGG1300 and (MATH1051 or MATH1071)
```

It preserves the nested structure in `data/prereq_logic.csv` and also creates a flattened edge table in `data/prereq_edges.csv`. The flattened table is convenient for graph traversal, but it cannot express the difference between “both courses” and “either course”. Use the logic JSON when that distinction matters.

The parser writes unsupported or ambiguous text to `data/manual_review.csv`. A row can contain a credit requirement, a prior-school qualification, prose mixed with course codes, or a website format that the parser does not recognize.

## 7. Complete manual review

Manual review is a deliberate part of the workflow. It prevents uncertain text from becoming a false prerequisite edge.

Open `data/manual_review.csv` and inspect each row. The template records the course, field, original text, and reason for review. Use a spreadsheet to decide whether the item is:

- a course edge that can be added;
- a recommended prerequisite;
- a special non-course requirement;
- or an item that should remain unresolved.

Run:

```r
source("03_review.R")
```

The optional desktop `edit()` workflow may not work on a headless computer. Spreadsheet editing is the portable path. Do not invent a course edge for statements such as “complete 32 units” or “achieve a grade of C in Year 12 Mathematics”. Those belong in the special-requirements output.

## 8. Build the graph

Run:

```r
source("04_build_graph.R")
```

The builder reads the course table and edge table, creates a `tidygraph` object, and adds external prerequisite nodes. An external node is a real course code referenced by an edge but absent from the selected plan. It is retained because removing it would hide a real dependency.

The stage writes:

- `data/graph_object.rds`, the graph used by selectors;
- `data/key_courses.csv`, a ranking by direct and downstream influence.

It also checks whether the graph is a DAG. A cycle usually means that the source data contains a circular rule or that a prerequisite direction was entered incorrectly.

## 9. Load and tag a graph

Start an interactive analysis with:

```r
source("config.R")
source("R/visualize_graph.R")
g <- readRDS(file.path(DATA_DIR, "graph_object.rds"))
g <- tag_course_status(g, COMPLETED_COURSES, CURRENT_COURSES)
```

Always tag the graph before plotting if you want completed and current courses to have distinct colors. Tagging does not remove nodes or edges.

## 10. Use every selector

### 10.1 Exact selection

Use `select_courses(g, courses)` when the question is “show exactly these courses and links between them”.

```r
g_selected <- select_courses(g, c("CSSE2002", "CSSE2310"))
plot_course_graph(g_selected, "output/exact_selection.png",
                  title = "Two selected courses")
```

### 10. Upstream prerequisites

Use `select_ancestors(g, courses, depth)` when the question is “what must be completed before this course?” A depth of 1 means direct prerequisites. `Inf` follows all reachable upstream nodes.

```r
g_upstream <- select_ancestors(g, "CSSE4010", depth = 2)
plot_course_graph(g_upstream, "output/upstream_two_levels.png",
                  title = "Two levels of prerequisites")
```

### 10. Downstream unlocks

Use `select_descendants(g, courses, depth)` when the question is “what can this course unlock?”

```r
g_downstream <- select_descendants(g, "CSSE1001", depth = Inf)
plot_course_graph(g_downstream, "output/unlocked_courses.png",
                  title = "Courses unlocked by CSSE1001")
```

### 10. Two-way neighborhood

Use `select_neighborhood(g, courses, depth)` for a local planning view around one or more courses. Both prerequisites and downstream courses are included.

```r
g_local <- select_neighborhood(g, "CSSE2310", depth = 2)
plot_course_graph(g_local, "output/course_neighborhood.png",
                  title = "CSSE2310 two-level neighborhood")
```

### 10. Hard prefix filter

Use `select_by_prefix(g, prefixes)` to remove every course outside one or more four-letter disciplines:

```r
g_disciplines <- select_by_prefix(g, c("CSSE", "ELEC"))
plot_course_graph(g_disciplines, "output/csse_elec_only.png",
                  title = "CSSE and ELEC courses only")
```

This is a structural filter. If a CSSE course depends on a MATH course, the MATH node disappears when only CSSE is retained. That behavior is intentional.

### 10.6 Soft prefix highlighting

Use `highlight_prefix` in `plot_course_graph()` when you want to keep all relationships and only emphasize selected disciplines:

```r
g_local |>
  plot_course_graph("output/highlighted_disciplines.png",
                    highlight_prefix = c("CSSE", "ELEC"),
                    title = "Complete neighborhood with disciplines highlighted")
```

Soft highlighting is usually the better choice for prerequisite analysis because it preserves cross-discipline context.

## 11. Combine selectors safely

Selectors return a graph, so they can be chained:

```r
select_ancestors(g, "CSSE4010", depth = 3) |>
  select_by_prefix(c("CSSE", "MATH")) |>
  plot_course_graph("output/csse_math_chain.png",
                    title = "CSSE4010 prerequisites after a hard prefix filter")
```

Apply traversal before hard filtering when you want to discover the full relevant network first. Apply the hard filter last when you intentionally want to remove other disciplines. Use highlighting instead of filtering when cross-discipline edges should remain visible.

## 12. Customize plots

`plot_course_graph()` accepts:

- `output_file`, the PNG path;
- `title`, the plot title;
- `highlight_prefix`, prefixes to emphasize;
- `width` and `height`, in inches;
- `dpi`, the output resolution.

```r
plot_course_graph(g_local,
                  output_file = "output/large_network.png",
                  title = "Planning network",
                  width = 16,
                  height = 11,
                  dpi = 300)
```

The fill color represents study status. Focus nodes receive a red outline when a selector names them. External nodes are smaller and lighter. Edge line type distinguishes prerequisite and recommended-prerequisite relations.

## 13. Generate statistics

The statistics functions read CSV files and return ggplot objects after saving PNG files:

```r
source("R/plot_stats.R")
plot_key_courses("data/key_courses.csv", output_file = "output/key_courses.png")
plot_prefix_by_level("data/courses_info.csv", output_file = "output/prefix_level.png")
plot_prereq_count_by_level("data/courses_info.csv", "data/prereq_edges.csv",
                           output_file = "output/prerequisite_load.png")
plot_class_hours("data/courses_info.csv", output_file = "output/contact_hours.png")
plot_assessment_mix("data/courses_info.csv", output_file = "output/assessment_mix.png")
```

The prerequisite-count plot counts OR alternatives separately. Treat that measure as a listed-prerequisite upper bound, not the number of courses a student must necessarily complete.

## 14. Practice without scraping

The `examples/` directory contains a captured dataset and figures. Copy the sample files into `data/` if you want to practice the parser, graph, and visualization stages without a network request. Then run `02_parse.R` through `05_visualize.R`.

The ready-made selector script is:

```r
source("examples/selector_examples.R")
```

It demonstrates exact selection, upstream traversal, downstream traversal, a neighborhood, and a hard prefix filter.

## 15. Reproducibility checklist

Before sharing an analysis, record the program code, route type, academic year, retrieval date, completed courses, current courses, and the version or commit of this repository. Keep the generated CSV files with the figures so another person can distinguish a changed UQ source page from a changed plotting choice.

## 16. Troubleshooting checklist

- If Chrome cannot start, install or update Google Chrome and run the scraper again.
- If no course codes are found, verify the route, code, and year in a browser.
- If only one course fails, inspect the per-course failure message and retry later.
- If many fields are missing, the UQ HTML identifiers may have changed; save the page and open an issue.
- If a selector reports an unknown course, check spelling and inspect `igraph::V(g)$course_code`.
- If the graph is too dense, reduce traversal depth or select a narrower neighborhood.
- If a cross-discipline prerequisite disappeared, use `highlight_prefix` instead of `select_by_prefix()`.
- If a prerequisite is prose rather than a course expression, leave it in manual review or special requirements.
