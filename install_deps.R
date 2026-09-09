required <- c("chromote", "rvest", "httr", "dplyr", "stringr", "tibble", "tidyr", "jsonlite", "tidygraph", "igraph", "ggraph", "ggplot2", "scales", "RColorBrewer")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
cat(sprintf("Dependencies ready: %d package(s).\n", length(required)))
