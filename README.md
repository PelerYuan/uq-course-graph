# UQ Course Graph

UQ Course Graph collects public University of Queensland course information, parses prerequisite text, builds a directed dependency graph, and produces network and statistics plots. The workflow is designed for a student who wants to change a plan code in one configuration file and run the pipeline.

## Requirements

- Windows, macOS, or Linux
- R 4.1 or newer
- Google Chrome (required by `chromote` for JavaScript-rendered plan pages)
- Internet access to `programs-courses.uq.edu.au`

Install R packages once:

```r
source("install_deps.R")
```

## Configure and run

Edit `config.R`:

```r
PROGRAM_PLAN_CODE <- "ELECEX2350"
ACADEMIC_YEAR <- 2026
PROGRAM_ROUTE_TYPE <- "plan" # use "program" when the UQ URL uses that route
COMPLETED_COURSES <- c("MATH1051")
CURRENT_COURSES <- c("CSSE2310")
```

Run the stages from the project directory:

```r
source("01_scrape.R")
source("02_parse.R")
source("03_review.R")
source("04_build_graph.R")
source("05_visualize.R")
```

Generated data is written to `data/`; plots are written to `output/`.

## Finding a plan code

Open the UQ Programs and Courses website, search for your degree or major, open the requirements page, and copy the code in the URL. A plan URL has the form `/requirements/plan/CODE/YEAR`; a program URL has `/requirements/program/CODE/YEAR`. Set both `PROGRAM_PLAN_CODE` and `PROGRAM_ROUTE_TYPE` accordingly.

## Manual review

Some prerequisite statements contain rules that cannot be represented as course-to-course edges. The parser writes these to `data/manual_review.csv`. Review or complete `data/manual_review_template.csv` with a spreadsheet, then run the review stage again. The optional R `edit()` workflow may require a desktop GUI and is not recommended on headless machines.

## Graph selectors

After building the graph, selectors can be combined with the plotting function:

```r
source("R/visualize_graph.R")
g <- tag_course_status(readRDS("data/graph_object.rds"), COMPLETED_COURSES, CURRENT_COURSES)
select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph("output/csse4010_prerequisites.png")
```

`select_by_prefix()` is a hard filter and removes other disciplines. `highlight_prefix` in `plot_course_graph()` keeps the complete graph and only changes emphasis.

## Caveats

- UQ page structure and available years can change. The scraper stops with an explanatory error when no course codes are rendered.
- Flattened prerequisite edge counts treat `A or B` as two listed alternatives; they are an upper bound on courses that must actually be completed.
- External prerequisite courses are retained as graph nodes even when they are outside the selected plan.
- Use a polite request delay. This tool reads public course information and should not be used for high-volume scraping.
