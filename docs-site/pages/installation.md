# Installation

Choose the installed package for an R session, or clone the repository to use the numbered scripts and gallery recipes. Both use the same functions. The package is named `uqcoursegraph`; the GitHub repository is `uq-course-graph`.

## Install the package from GitHub

Use R 4.1 or newer. The CI checks the current R release on Windows and Linux. Runtime dependencies have their own R requirements, so a current R release is recommended.

```r
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_github("PelerYuan/uq-course-graph", upgrade = "never")
library(uqcoursegraph)
packageVersion("uqcoursegraph")
```

The package is not on CRAN. A source archive can also be built from a clone with `R CMD build .` and installed with `R CMD INSTALL uqcoursegraph_0.2.0.tar.gz` after its dependencies are installed.

## Use a source checkout

```sh
git clone https://github.com/PelerYuan/uq-course-graph.git
cd uq-course-graph
```

Open R in that folder, then run:

```r
source("install_deps.R")
source("scripts/load_project.R")
file.copy("config.example.R", "config.R", overwrite = FALSE)
```

`config.R` is a local, ignored file. The copy command deliberately preserves an existing configuration. Edit it before collecting your own curriculum. You can now use all documented functions without installing the package. Source individual modules only when developing them: they share validation helpers loaded by `scripts/load_project.R`.

## Browser requirements

Only live requirements-page collection needs Chrome and the optional `chromote` package. The installed package's graph, parser, review, and plotting features work without a browser or network access.

```r
install.packages("chromote", repos = "https://cloud.r-project.org")
chromote::find_chrome()
```

The checkout dependency script includes `chromote`. If Chrome cannot be found, install Chrome or set `CHROMOTE_CHROME` to the executable location for your environment.

## Verify a first result

Follow the [complete workflow](getting-started.md) to run a small offline example, then use the [gallery](gallery.md) for larger captured networks. Check the installation with `?uq_config` and `?plot_course_graph` in an installed package. Development tests and package checks are described in the repository's contributing guide.
