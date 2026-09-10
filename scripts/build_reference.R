# Build the website's function reference from the same Rd files shipped in R.
source("scripts/load_project.R")
check <- "--check" %in% commandArgs(trailingOnly = TRUE)
groups <- list(
  scraping = c("fetch_program_courses", "extract_course_info", "fetch_course_details"),
  parsing = c("is_clean_prereq", "tokenize_prereq", "parse_prereq_expr", "flatten_prereq_codes", "parse_all_prerequisites"),
  review = c("generate_review_template", "apply_manual_overrides", "review_manually"),
  graph = c("build_course_graph", "check_dag", "rank_key_courses"),
  selectors = c("select_courses", "select_ancestors", "select_descendants", "select_neighborhood", "select_by_prefix"),
  plotting = c("tag_course_status", "plot_course_graph", "plot_key_courses", "plot_prefix_by_level", "plot_prereq_count_by_level", "plot_class_hours", "plot_assessment_mix"),
  workflow = c("uq_config", "load_config", "project_paths", "example_file", "import_course_data", "run_stage", "run_pipeline"))
plain <- function(x) trimws(gsub("[[:space:]]+", " ", paste(unlist(x), collapse = "")))
for (group in names(groups)) {
  lines <- c(paste0("# ", tools::toTitleCase(group), " reference"), "",
    "Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.", "",
    "For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source(\"scripts/load_project.R\")` first.", "")
  for (name in groups[[group]]) {
    rd <- tools::parse_Rd(file.path("man", paste0(name, ".Rd")))
    section <- function(tag) Filter(function(x) identical(attr(x, "Rd_tag"), tag), rd)
    usage <- paste(deparse(args(get(name))), collapse = "\n")
    usage <- sub("^function", name, sub("\\s*NULL$", "", usage))
    lines <- c(lines, paste0("## `", name, "()`"), "", plain(section("\\description")), "",
      "```r", usage, "```", "", "| Argument | Meaning |", "| --- | --- |")
    arguments <- section("\\arguments")[[1]]
    items <- Filter(function(x) identical(attr(x, "Rd_tag"), "\\item"), arguments)
    for (item in items) lines <- c(lines, paste0("| `", plain(item[[1]]), "` | ", gsub("|", "\\|", plain(item[[2]]), fixed = TRUE), " |"))
    lines <- c(lines, "", paste0("**Returns:** ", plain(section("\\value"))), "")
  }
  lines <- strsplit(paste(lines, collapse = "\n"), "\n", fixed = TRUE)[[1]]
  lines <- sub("[[:blank:]]+$", "", lines)
  while (length(lines) && !nzchar(tail(lines, 1))) lines <- head(lines, -1)
  path <- file.path("docs-site/pages/reference", paste0(group, ".md"))
  if (check) {
    if (!file.exists(path) || !identical(readLines(path, warn = FALSE), lines)) stop("Stale reference: ", path)
  } else writeLines(lines, path, useBytes = TRUE)
}
message(if (check) "Reference pages are synchronized." else "Generated reference pages for 33 public functions.")
