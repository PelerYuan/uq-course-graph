# UQ Course Graph

[![R checks](https://github.com/PelerYuan/uq-course-graph/actions/workflows/r-checks.yml/badge.svg)](https://github.com/PelerYuan/uq-course-graph/actions/workflows/r-checks.yml) [![Documentation](https://img.shields.io/badge/docs-read%20the%20guide-1976d2)](https://peleryuan.github.io/uq-course-graph/)

UQ Course Graph is a reproducible R workflow for collecting public University of Queensland course information, parsing prerequisite relationships, building a directed dependency graph, and exploring focused curriculum networks.

![Example dependency graph](examples/course_dependency_graph.png)

## Documentation

The complete user documentation lives in the [Docsify guide](https://peleryuan.github.io/uq-course-graph/). It is the canonical entry point and covers installation, configuration, every pipeline stage, selector recipes, function reference, visual interpretation, troubleshooting, and reproducibility.

Start with the [complete workflow](https://peleryuan.github.io/uq-course-graph/#/pages/getting-started), or open the [selector reference](https://peleryuan.github.io/uq-course-graph/#/pages/reference/selectors) if you already have a graph object.

Browse the [gallery](https://page.peler.top/uq-course-graph/#/pages/gallery) for 12 real figures with complete R code. Every example runs on bundled data before you scrape your own curriculum.

## Quick start

```r
source("install_deps.R")
file.copy("config.example.R", "config.R")
# edit config.R
source("01_scrape.R")
source("02_parse.R")
source("03_review.R")
source("04_build_graph.R")
source("05_visualize.R")
```

The numbered scripts are intentionally small entry points. Reusable functions live in `R/`. Captured sample outputs and figures live in `examples/` so the analytical stages can be practiced without scraping.

## Repository map

```text
R/          reusable functions
docs-site/  canonical user documentation
examples/   captured data and figures
tests/      testthat tests
01_*.R      through 05_*.R user-facing stages
```

## Contributing

Development policies are documented separately in [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [NEWS.md](NEWS.md).

## License

MIT. See [LICENSE](LICENSE).
