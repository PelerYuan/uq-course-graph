#' Create validated workflow configuration
#'
#' All managed stages use the same settings. Data and outputs are separated by route, code, and requested year.
#'
#' @param program_code Alphanumeric program or plan code from a UQ requirements URL.
#' @param academic_year Integer requested catalogue year. In fetch_course_details(), NULL requests the current page.
#' @param route_type Either "plan" or "program".
#' @param data_dir Base data directory. A route-code-year subdirectory is added automatically.
#' @param output_dir Directory for generated files, or the base output directory in configuration.
#' @param completed Character vector of course codes to mark completed. Must not overlap current.
#' @param current Character vector of course codes to mark in progress.
#' @param delay Non-negative delay in seconds between requests. Retries use exponential backoff.
#' @param timeout Positive request timeout in seconds.
#' @param retries Non-negative integer number of retries after the initial attempt.
#' @param user_agent Non-empty User-Agent string sent with requests.
#' @return A uq_config list.
#' @export
uq_config <- function(program_code = "ELECEX2350", academic_year = 2026,
                      route_type = "plan", data_dir = "data", output_dir = "output",
                      completed = character(), current = character(), delay = 1,
                      timeout = 30, retries = 2, user_agent = "uqcoursegraph/0.2.0") {
  .text_scalar(program_code, "program_code")
  if (!grepl("^[A-Za-z0-9]+$", program_code)) stop("program_code must be alphanumeric.", call. = FALSE)
  .number_scalar(academic_year, "academic_year", 2000, integer = TRUE)
  if (length(route_type) != 1L || is.na(route_type) || !route_type %in% c("plan", "program")) stop("route_type must be plan or program.", call. = FALSE)
  .text_scalar(data_dir, "data_dir")
  .text_scalar(output_dir, "output_dir")
  .course_codes(completed)
  .course_codes(current)
  if (length(intersect(completed, current))) stop("Completed and current courses must not overlap.", call. = FALSE)
  .number_scalar(delay, "delay")
  .number_scalar(timeout, "timeout", 0.1)
  .number_scalar(retries, "retries", integer = TRUE)
  .text_scalar(user_agent, "user_agent")
  structure(list(program_code = program_code, academic_year = academic_year, route_type = route_type,
    data_dir = data_dir, output_dir = output_dir, completed = completed, current = current,
    delay = delay, timeout = timeout, retries = retries, user_agent = user_agent), class = "uq_config")
}

#' Load local workflow settings
#'
#' Maps uppercase settings from config.R to uq_config(). Missing required source settings and invalid values cause errors.
#'
#' @param path Path to a local R configuration file. Only source a configuration file you trust.
#' @return A validated uq_config list.
#' @export
load_config <- function(path = "config.R") {
  if (!file.exists(path)) stop("Missing config.R. Copy config.example.R and edit the local copy first.", call. = FALSE)
  values <- new.env(parent = baseenv())
  sys.source(path, envir = values)
  mapping <- c(program_code = "PROGRAM_CODE", academic_year = "ACADEMIC_YEAR", route_type = "PROGRAM_ROUTE_TYPE",
    data_dir = "DATA_DIR", output_dir = "OUTPUT_DIR", completed = "COMPLETED_COURSES", current = "CURRENT_COURSES",
    delay = "REQUEST_DELAY", timeout = "REQUEST_TIMEOUT", retries = "REQUEST_RETRIES", user_agent = "USER_AGENT")
  required <- c("PROGRAM_CODE", "ACADEMIC_YEAR", "PROGRAM_ROUTE_TYPE")
  missing <- setdiff(required, ls(values))
  if (length(missing)) stop("Missing configuration values: ", paste(missing, collapse = ", "), call. = FALSE)
  args <- lapply(mapping[mapping %in% ls(values)], get, envir = values, inherits = FALSE)
  do.call(uq_config, args)
}

#' Locate one curriculum workspace
#'
#' Computes paths without creating files. Each source uses its own route-code-year subdirectory.
#'
#' @param config Validated configuration returned by uq_config() or load_config().
#' @return A named list of absolute input, output, review, graph, and manifest paths.
#' @export
project_paths <- function(config) {
  if (!inherits(config, "uq_config")) stop("Use uq_config() or load_config() to create configuration.", call. = FALSE)
  config <- do.call(uq_config, unclass(config))
  id <- paste(config$route_type, config$program_code, config$academic_year, sep = "-")
  absolute <- function(x) {
    x <- path.expand(x)
    if (!grepl("^(/|[A-Za-z]:|\\\\)", x)) x <- file.path(getwd(), x)
    gsub("\\", "/", x, fixed = TRUE)
  }
  data <- file.path(absolute(config$data_dir), id)
  output <- file.path(absolute(config$output_dir), id)
  list(id = id, data = data, output = output, courses = file.path(data, "courses_info.csv"),
    edges = file.path(data, "prereq_edges.csv"), logic = file.path(data, "prereq_logic.csv"),
    review = file.path(data, "manual_review.csv"), template = file.path(data, "manual_review_template.csv"),
    special = file.path(data, "special_requirements.csv"), graph = file.path(data, "graph_object.rds"),
    manifest = file.path(data, "run_manifest.json"))
}

.requirements_url <- function(config) paste0("https://programs-courses.uq.edu.au/requirements/",
  config$route_type, "/", config$program_code, "/", config$academic_year)

.init_manifest <- function(config) {
  paths <- project_paths(config)
  dir.create(paths$data, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$output, recursive = TRUE, showWarnings = FALSE)
  manifest <- if (file.exists(paths$manifest)) jsonlite::read_json(paths$manifest) else
    list(schema_version = 1L, source_id = paths$id, created_at = .utc_now(), stages = list())
  if (!identical(manifest$source_id, paths$id)) stop("Manifest source does not match configuration.", call. = FALSE)
  manifest$config <- unclass(config)
  manifest$requirements_url <- .requirements_url(config)
  manifest$package_version <- .uq_version
  manifest$updated_at <- .utc_now()
  .write_json(manifest, paths$manifest)
  manifest
}

.fingerprints <- function(paths) lapply(paths, function(path) list(path = path, sha256 = .file_hash(path)))

.record_stage <- function(config, stage, inputs = character(), outputs = character(), metadata = list()) {
  paths <- project_paths(config)
  manifest <- .init_manifest(config)
  if (stage %in% c("import", "scrape")) manifest$source_stage <- stage
  manifest$stages[[stage]] <- list(completed_at = .utc_now(), inputs = .fingerprints(inputs),
    outputs = .fingerprints(outputs), config = unclass(config), metadata = metadata)
  .write_json(manifest, paths$manifest)
  utils::capture.output(utils::sessionInfo(), file = file.path(paths$data, "sessionInfo.txt"))
  manifest
}

.require_stage <- function(config, stage) {
  manifest <- .init_manifest(config)
  record <- manifest$stages[[stage]]
  if (is.null(record)) stop("Run the ", stage, " stage first.", call. = FALSE)
  for (item in c(record$inputs, record$outputs)) {
    if (!file.exists(item$path) || !identical(.file_hash(item$path), item$sha256))
      stop("Stale ", stage, " result: ", item$path, ". Rerun that stage and its successors.", call. = FALSE)
  }
  invisible(record)
}

#' Locate bundled example data
#'
#' Provides offline input files in an installed package or a source checkout. See the bundled README for provenance and limitations.
#'
#' @param name Name of a bundled example CSV: courses.csv, gallery_courses.csv, prereq_edges.csv, or demo_courses.csv (synthetic).
#' @return A file path.
#' @export
example_file <- function(name = "courses.csv") {
  if (length(name) != 1L || is.na(name) || !name %in% c("courses.csv", "gallery_courses.csv", "prereq_edges.csv", "demo_courses.csv"))
    stop("Unknown bundled example file.", call. = FALSE)
  file <- system.file("extdata", name, package = "uqcoursegraph")
  if (!nzchar(file)) file <- file.path("inst", "extdata", name)
  if (!file.exists(file)) stop("Bundled example file is missing; reinstall the package.", call. = FALSE)
  file
}

#' Import an offline metadata snapshot
#'
#' Validates a supplied table and records its checksum and source label. The import timestamp is not treated as its original retrieval date.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param config Validated configuration returned by uq_config() or load_config().
#' @param overwrite Logical; explicitly allow replacing an existing imported snapshot.
#' @param source_label Description of the offline data source, recorded in the manifest.
#' @return Workspace paths invisibly.
#' @export
import_course_data <- function(courses_file, config = uq_config(), overwrite = FALSE,
                               source_label = "User-supplied offline snapshot") {
  .text_scalar(source_label, "source_label")
  courses <- .read_csv(courses_file)
  .validate_courses(courses, prerequisite_columns = TRUE)
  if (!nrow(courses)) stop("The imported course list is empty.", call. = FALSE)
  paths <- project_paths(config)
  .init_manifest(config)
  if (file.exists(paths$courses) && !overwrite) stop("Course data already exists. Use overwrite = TRUE only when replacing this snapshot intentionally.", call. = FALSE)
  .write_csv(courses, paths$courses)
  .record_stage(config, "import", outputs = paths$courses,
    metadata = list(source_label = source_label, source_file_sha256 = .file_hash(courses_file),
      imported_at = .utc_now(), retrieval_date = NULL))
  invisible(paths)
}

#' Run a validated workflow stage
#'
#' Uses one configuration and records file checksums in run_manifest.json. Review pauses when decisions are pending. Graph and plot refuse stale prerequisites. Figures receive a manifest sidecar and the data directory records sessionInfo().
#'
#' @param stage One of scrape, parse, review, graph, or plot.
#' @param config Validated configuration returned by uq_config() or load_config().
#' @param refresh Logical; TRUE downloads successful cached records again.
#' @return Stage-specific data invisibly: a data frame, result list, graph, or plot. Pending review returns status and template path.
#' @export
run_stage <- function(stage, config = uq_config(), refresh = FALSE) {
  stage <- match.arg(stage, c("scrape", "parse", "review", "graph", "plot"))
  paths <- project_paths(config)
  .init_manifest(config)
  if (stage == "scrape") {
    codes_file <- file.path(paths$data, "course_codes.csv")
    codes <- fetch_program_courses(.requirements_url(config), codes_file, timeout = config$timeout, user_agent = config$user_agent)
    courses <- fetch_course_details(codes$course_code, paths$courses, delay = config$delay,
      timeout = config$timeout, retries = config$retries, academic_year = config$academic_year,
      user_agent = config$user_agent, refresh = refresh)
    .record_stage(config, stage, outputs = c(codes_file, paths$courses),
      metadata = list(failed = sum(courses$fetch_status != "success")))
    .validate_courses(courses, prerequisite_columns = TRUE)
    return(invisible(courses))
  }
  if (stage == "parse") {
    manifest <- .init_manifest(config)
    if (is.null(manifest$source_stage)) stop("Import a snapshot or run scrape before parsing.", call. = FALSE)
    .require_stage(config, manifest$source_stage)
    result <- parse_all_prerequisites(.read_csv(paths$courses), paths$data)
    .record_stage(config, stage, inputs = paths$courses,
      outputs = file.path(paths$data, c("prereq_edges_auto.csv", "prereq_logic_auto.csv", "manual_review.csv")))
    return(invisible(result))
  }
  .require_stage(config, "parse")
  if (stage == "review") {
    template <- generate_review_template(paths$review, paths$template)
    if (any(template$status == "pending")) {
      message("Edit ", paths$template, "; mark each row approved or special, then rerun review.")
      return(invisible(list(status = "pending", template = paths$template)))
    }
    result <- apply_manual_overrides(paths$template, paths$edges, paths$logic, paths$special, paths$review)
    .record_stage(config, stage, inputs = c(paths$review, paths$template,
      file.path(paths$data, c("prereq_edges_auto.csv", "prereq_logic_auto.csv"))),
      outputs = c(paths$edges, paths$logic, paths$special))
    return(invisible(c(list(status = "complete"), result)))
  }
  .require_stage(config, "review")
  if (stage == "graph") {
    g <- build_course_graph(paths$courses, paths$edges)
    if (!check_dag(g)) stop("Graph stage stopped because the graph contains a cycle.", call. = FALSE)
    g <- igraph::set_graph_attr(g, "source_id", paths$id)
    ranking_file <- file.path(paths$data, "key_courses.csv")
    .write_csv(rank_key_courses(g), ranking_file)
    saveRDS(g, paths$graph)
    .record_stage(config, stage, inputs = c(paths$courses, paths$edges, paths$logic, paths$special),
      outputs = c(paths$graph, ranking_file))
    return(invisible(g))
  }
  .require_stage(config, "graph")
  g <- tag_course_status(readRDS(paths$graph), config$completed, config$current)
  output_file <- file.path(paths$output, "course_dependency_graph.png")
  plot <- plot_course_graph(g, output_file, title = paste("UQ Course Dependencies:", paths$id))
  manifest <- .record_stage(config, stage, inputs = paths$graph, outputs = output_file,
    metadata = list(seed = 20260910, width = 20, height = 13, dpi = 300))
  .write_json(manifest, file.path(paths$output, "run_manifest.json"))
  invisible(plot)
}

#' Run ordered workflow stages
#'
#' The default runs offline stages after import. Stops at pending review; resume with review, graph, and plot after editing. Include scrape explicitly for network collection.
#'
#' @param config Validated configuration returned by uq_config() or load_config().
#' @param stages Unique stage names in pipeline order. The default excludes network collection.
#' @return Workspace paths invisibly after successful completion.
#' @export
run_pipeline <- function(config = uq_config(), stages = c("parse", "review", "graph", "plot")) {
  allowed <- c("scrape", "parse", "review", "graph", "plot")
  if (!is.character(stages) || !length(stages) || anyNA(stages) || any(!stages %in% allowed) || anyDuplicated(stages) ||
      is.unsorted(match(stages, allowed))) stop("stages must be unique names in pipeline order.", call. = FALSE)
  for (stage in stages) {
    result <- run_stage(stage, config)
    if (stage == "review" && identical(result$status, "pending"))
      stop("Pipeline paused for manual review. Edit the template and resume with review, graph, plot.", call. = FALSE)
  }
  invisible(project_paths(config))
}
