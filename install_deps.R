# Install runtime dependencies for the source-checkout workflow.
imports <- read.dcf("DESCRIPTION")[1, "Imports"]
required <- unique(c(trimws(gsub("\\s*\\([^)]*\\)", "", strsplit(imports, ",")[[1]])), "chromote"))
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Runtime dependencies ready. Install testthat and roxygen2 for development checks.")
