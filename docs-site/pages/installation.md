# Installation

## System requirements

- R 4.1 or newer;
- Google Chrome;
- internet access for scraping;
- a writable clone of the repository.

Chrome is required because the UQ requirements page renders its course list with JavaScript. Static HTTP requests are used for individual course pages.

## Install R packages

From the repository root:

```r
source("install_deps.R")
```

The script checks packages before installing them. It includes `chromote`, `rvest`, `httr`, `dplyr`, `stringr`, `tibble`, `tidyr`, `jsonlite`, `tidygraph`, `igraph`, `ggraph`, `ggplot2`, `scales`, and `RColorBrewer`.

## Run without scraping

The `examples/` directory contains captured output. Copy the example data into `data/` if you want to practice parsing, graph construction, and plotting without contacting UQ.

## Verify the installation

```r
files <- list.files(pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
for (file in files) parse(file = file)
```

Then run the test suite:

```r
testthat::test_dir("tests/testthat")
```
