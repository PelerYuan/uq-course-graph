# Complete workflow

Start with a small offline run to learn the file flow. Then collect a real UQ curriculum using the same API. Keep [the gallery](gallery.md) open if you want to compare complete plotting recipes.

## 1. Load the functions

After [installation](installation.md), use one of these entry points:

```r
# Installed package:
library(uqcoursegraph)
```

Or, from the repository root:

```r
# Source checkout:
source("scripts/load_project.R")
```

The examples below work with either entry point.

## 2. Run an offline example

This four-course file is **synthetic tutorial data**, not UQ enrolment advice. It uses only explicit rules, so it needs no manual decisions. The gallery separately uses a captured public curriculum snapshot.

```r
config <- uq_config(
  program_code = "DEMO", academic_year = 2026,
  data_dir = "data", output_dir = "output",
  completed = "CSSE1001", current = "CSSE2010"
)
paths <- project_paths(config)
import_course_data(
  example_file("demo_courses.csv"), config,
  source_label = "Bundled synthetic tutorial"
)
run_pipeline(config)
paths$graph
paths$output
```

Open `output/plan-DEMO-2026/course_dependency_graph.png`. Its adjacent `.manifest.json` identifies the input hashes, selected nodes, plot settings, and software session. `run_manifest.json` records the pipeline stages. The graph and CSVs are under `data/plan-DEMO-2026/`.

Import is deliberately protected: a second `import_course_data()` call refuses to overwrite an existing snapshot. To rerun the same analysis, call `run_pipeline(config)`. To intentionally replace an input snapshot, pass `overwrite = TRUE` to import and rerun the downstream stages. Existing inputs are never silently migrated from the old unscoped `data/` folder.

## 3. Collect your curriculum

Open your requirements page on the UQ Programs and Courses website. Copy its code, route type, and year into configuration. A URL containing `/requirements/plan/` uses `route_type = "plan"`; `/requirements/program/` uses `"program"`.

```r
config <- uq_config(
  program_code = "ELECEX2350", academic_year = 2026,
  route_type = "plan", timeout = 30, retries = 2, delay = 1
)
paths <- project_paths(config)
run_stage("scrape", config)
```

This creates `course_codes.csv` and `courses_info.csv` in `paths$data`. Inspect `fetch_status`, `source_url`, `academic_year`, `retrieved_at`, `attempts`, and `error`. A failed request is retained for diagnosis and retried on the next run. Successful records from the same URL and requested year are reused. Use `run_stage("scrape", config, refresh = TRUE)` when intentionally refreshing successful records.

The source stage stops if failed or incomplete records remain. Resolve them before parsing. A requested year is recorded explicitly, but UQ controls whether its course endpoint serves the requested historical version; inspect the source when historical accuracy matters.

## 4. Parse and review

```r
run_stage("parse", config)
run_stage("review", config)
```

Parsing writes `prereq_edges_auto.csv` and `prereq_logic_auto.csv` as automatic base tables, plus canonical `prereq_edges.csv` and `prereq_logic.csv`. Unsupported prose, malformed expressions, and bare commas enter `manual_review.csv`.

If there are flagged rows, review creates `manual_review_template.csv` and reports `pending`. Open the template in a spreadsheet. Edit only `status`, `cleaned_text`, and `note`:

| Status | What to enter | What happens |
| --- | --- | --- |
| `pending` | Leave this while you investigate | Graph building remains blocked |
| `approved` | A checked expression such as `CSSE1001 and MATH1051` | Its course relationships are added |
| `special` | An explanatory note describing the non-course rule | The original text is retained in `special_requirements.csv` |

Do not mark every row approved merely to finish the run. Grade, unit, permission, and degree rules cannot be reduced to course edges automatically. If a mixed condition needs to remain visible as a whole, retain it as `special`. Read the [review walkthrough](pipeline/review.md) for examples.

After saving the CSV, resume:

```r
run_stage("review", config)
run_stage("graph", config)
run_stage("plot", config)
```

Re-running review preserves decisions for unchanged source text and does not duplicate edges. When source text changes, the old decision is archived and the new expression becomes pending.

## 5. Explore a question

```r
g <- readRDS(paths$graph)
g <- tag_course_status(g, completed = character(), current = character())
select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph(
    file.path(paths$output, "csse4010-prerequisites.png"),
    title = "CSSE4010: prerequisite context", width = 12, height = 8
  )
```

Change the queried code to one in your graph. Arrows point **from prerequisite to dependent course**. Traversal includes prerequisite and recommended-prerequisite edges; neither reachability nor a status color evaluates complete enrolment eligibility.

![Example prerequisite context](../assets/images/gallery/04-two-levels.png)

The image above is the captured gallery example, not the synthetic four-course demo. Continue with the [selector guide](selectors/overview.md) and [function reference](reference/selectors.md).

## Numbered scripts and resuming

In a source checkout, edit `config.R` once and use `01_scrape.R` through `05_visualize.R`. Every script calls `load_config()` and the matching `run_stage()`. Run `03_review.R` once to prepare the template, edit it, then run it again to apply decisions. Only continue to `04_build_graph.R` after review completes.

For batch use, set `UQCOURSEGRAPH_CONFIG` to a different local configuration file. For the R API, `run_pipeline(config, stages = c("review", "graph", "plot"))` resumes after a review pause. Freshness checks refuse stale upstream results and tell you which stage to rerun.
