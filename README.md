# UQ Course Graph

[![R checks](https://github.com/PelerYuan/uq-course-graph/actions/workflows/r-checks.yml/badge.svg)](https://github.com/PelerYuan/uq-course-graph/actions/workflows/r-checks.yml)

Collect public University of Queensland course metadata, review prerequisite rules, and explore course networks with the `uqcoursegraph` R package. Graph reachability describes relationships; it does not decide enrolment eligibility or degree completion.

![Example dependency graph](docs-site/assets/images/gallery/04-two-levels.png)

## Documentation

The [documentation website](https://page.peler.top/uq-course-graph/) is the canonical user guide. Start with [installation](https://page.peler.top/uq-course-graph/#/pages/installation) and the [complete workflow](https://page.peler.top/uq-course-graph/#/pages/getting-started). Browse [12 illustrated gallery recipes](https://page.peler.top/uq-course-graph/#/pages/gallery) or consult the [API reference](https://page.peler.top/uq-course-graph/#/pages/reference/workflow).

## Install and try offline

```r
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_github("PelerYuan/uq-course-graph", upgrade = "never")
library(uqcoursegraph)
config <- uq_config(program_code = "DEMO", academic_year = 2026)
import_course_data(example_file("demo_courses.csv"), config,
                   source_label = "Bundled synthetic tutorial")
run_pipeline(config)
```

This synthetic example writes a graph and figure under source-specific `data/` and `output/` subdirectories. To use a clone without installing the package, run `source("install_deps.R")`, then `source("scripts/load_project.R")`. Numbered entry scripts remain available and all read the same local configuration.

Version 0.2.0 introduces explicit review statuses and source-specific directories. Read the [migration guide](https://page.peler.top/uq-course-graph/#/pages/migration) before using older data or review templates.

## Development

Reusable code is in `R/`; R help files are in `man/`; installed examples are in `inst/extdata/`; user documentation is in `docs-site/`. Tests and contributor instructions are described in [CONTRIBUTING.md](CONTRIBUTING.md). Changes are listed in [NEWS.md](NEWS.md).

## License

MIT; see [LICENSE.md](LICENSE.md). Public UQ source descriptions are attributed in the bundled example-data README.
