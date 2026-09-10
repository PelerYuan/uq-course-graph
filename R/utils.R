.uq_version <- "0.2.0"
.edge_fields <- c("prerequisite", "recommended_prerequisite")

.text_scalar <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x)))
    stop(name, " must be one non-empty string.", call. = FALSE)
  x
}
.number_scalar <- function(x, name, minimum = 0, integer = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < minimum || (integer && x != floor(x)))
    stop(name, " must be a finite ", if (integer) "integer " else "number ",
         ">= ", minimum, ".", call. = FALSE)
  x
}
.course_codes <- function(x, allow_empty = TRUE) {
  if (!is.character(x) || anyNA(x) || any(!grepl("^[A-Z]{4}[0-9]{4}$", x)) ||
      (!allow_empty && !length(x)))
    stop("Course codes must use four uppercase letters and four digits.", call. = FALSE)
  unique(x)
}
.columns <- function(x, columns, label = "Input") {
  missing <- setdiff(columns, names(x))
  if (length(missing)) stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  invisible(x)
}
.empty_table <- function(columns) {
  as.data.frame(stats::setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE)
}
.read_csv <- function(path, columns = character()) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  x <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                       colClasses = "character", na.strings = "NA")
  .columns(x, columns, basename(path))
  x
}
.write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(".uq-", tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(x, tmp, row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
  if (!file.rename(tmp, path)) stop("Could not replace output: ", path, call. = FALSE)
  invisible(path)
}
.write_json <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(".uq-", tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  jsonlite::write_json(x, tmp, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
  if (!file.rename(tmp, path)) stop("Could not replace output: ", path, call. = FALSE)
  invisible(path)
}
.file_hash <- function(path) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  digest::digest(file = path, algo = "sha256")
}
.utc_now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
.review_ids <- function(course, field, raw) {
  vapply(paste(course, field, raw, sep = "\n"), digest::digest,
         character(1), algo = "sha256", serialize = FALSE, USE.NAMES = FALSE)
}
.validate_courses <- function(x, prerequisite_columns = FALSE) {
  required <- c("course_code", "course_name")
  if (prerequisite_columns) required <- c(required, .edge_fields)
  .columns(x, required, "Course table")
  .course_codes(x$course_code)
  if (anyDuplicated(x$course_code)) stop("Duplicate course codes in course table.", call. = FALSE)
  if (anyNA(x$course_name) || any(!nzchar(trimws(x$course_name))))
    stop("Course metadata is incomplete; retry failed downloads before continuing.", call. = FALSE)
  if ("fetch_status" %in% names(x) && any(is.na(x$fetch_status) | x$fetch_status != "success"))
    stop("Failed downloads remain; rerun the scrape stage before continuing.", call. = FALSE)
  invisible(x)
}

.plot_manifest <- function(output_file, provenance = list(), options = list()) {
  .write_json(list(schema_version = 1L, generated_at = .utc_now(),
    package_version = .uq_version, image_sha256 = .file_hash(output_file),
    provenance = provenance, options = options,
    session = utils::capture.output(utils::sessionInfo())), paste0(output_file, ".manifest.json"))
}
