#' Create or update a review template
#'
#' Preserves status, cleaned_text, and note when source text is unchanged. New or changed expressions are pending. Removed entries are archived beside the template.
#'
#' @param manual_review_file Current parser review CSV containing source course, field, raw text, and reason.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return The current review data frame, also saved as CSV.
#' @export
generate_review_template <- function(manual_review_file = "manual_review.csv",
                                     output_file = "manual_review_template.csv") {
  review <- .read_csv(manual_review_file, c("course_code", "field", "raw_text", "reason"))
  review$review_id <- .review_ids(review$course_code, review$field, review$raw_text)
  review$status <- rep("pending", nrow(review))
  review$cleaned_text <- rep(NA_character_, nrow(review))
  review$note <- rep(NA_character_, nrow(review))
  if (file.exists(output_file)) {
    old <- .read_csv(output_file, c("course_code", "field", "raw_text", "cleaned_text", "note"))
    if (!"review_id" %in% names(old)) old$review_id <- .review_ids(old$course_code, old$field, old$raw_text)
    if (!"status" %in% names(old)) old$status <- rep("pending", nrow(old))
    if (anyDuplicated(old$review_id)) stop("Duplicate review IDs in existing template.", call. = FALSE)
    idx <- match(review$review_id, old$review_id)
    keep <- !is.na(idx)
    review[keep, c("status", "cleaned_text", "note")] <- old[idx[keep], c("status", "cleaned_text", "note")]
    stale <- old[!old$review_id %in% review$review_id, , drop = FALSE]
    if (nrow(stale)) {
      archive_file <- sub("\\.csv$", "_archive.csv", output_file)
      if (identical(archive_file, output_file)) archive_file <- paste0(output_file, ".archive.csv")
      archive <- if (file.exists(archive_file)) .read_csv(archive_file) else stale[FALSE, ]
      .write_csv(unique(dplyr::bind_rows(archive, stale)), archive_file)
    }
  }
  .write_csv(review, output_file)
  message("Review template: ", output_file, " (", sum(review$status == "pending", na.rm = TRUE), " pending).")
  review
}

#' Edit a review template interactively
#'
#' Optional desktop editor. For headless use, generate a template and edit its CSV in a spreadsheet.
#'
#' @param manual_review_file Current parser review CSV containing source course, field, raw text, and reason.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return The edited data frame.
#' @export
review_manually <- function(manual_review_file = "manual_review.csv",
                            output_file = "manual_review_template.csv") {
  if (!interactive()) stop("Use generate_review_template() and edit the CSV in a spreadsheet.", call. = FALSE)
  review <- generate_review_template(manual_review_file, output_file)
  edited <- utils::edit(review)
  .write_csv(edited, output_file)
  edited
}

#' Apply reviewed prerequisite decisions
#'
#' Requires every row to be approved or special. Approved rows require a valid cleaned expression; special rows require a note. Source columns must remain unchanged. Replaces affected relationships from automatic base tables, so repeated calls do not duplicate edges. All decisions are validated before result files are written.
#'
#' @param template_file Review template with stable review_id and status columns.
#' @param edges_file Path to a CSV containing course_code, prereq_code, and field.
#' @param logic_file Path to a CSV containing course_code, field, raw_text, and logic_tree.
#' @param special_file Output CSV for explicitly reviewed non-course requirements.
#' @param manual_review_file Current parser review CSV containing source course, field, raw text, and reason.
#' @return A list containing edges, logic, and special_requirements data frames.
#' @export
apply_manual_overrides <- function(template_file = "manual_review_template.csv",
                                   edges_file = "prereq_edges.csv",
                                   logic_file = "prereq_logic.csv",
                                   special_file = "special_requirements.csv",
                                   manual_review_file = file.path(dirname(template_file), "manual_review.csv")) {
  template <- .read_csv(template_file, c("review_id", "course_code", "field", "raw_text", "status", "cleaned_text", "note"))
  active <- .read_csv(manual_review_file, c("course_code", "field", "raw_text"))
  active_ids <- .review_ids(active$course_code, active$field, active$raw_text)
  if (anyDuplicated(template$review_id) || !setequal(template$review_id, active_ids) ||
      !identical(template$review_id, .review_ids(template$course_code, template$field, template$raw_text)))
    stop("Review template is stale or its source columns were edited. Regenerate the template.", call. = FALSE)
  if (anyNA(template$status) || any(!template$status %in% c("pending", "approved", "special")))
    stop("Review status must be pending, approved, or special.", call. = FALSE)
  if (any(template$status == "pending")) stop("Pending review rows remain. Set status to approved or special after inspection.", call. = FALSE)
  if (any(!template$field %in% .edge_fields)) stop("Unknown relationship field in review template.", call. = FALSE)
  base_path <- function(path) {
    automatic <- sub("\\.csv$", "_auto.csv", path)
    if (file.exists(automatic)) automatic else path
  }
  edges <- .read_csv(base_path(edges_file), c("course_code", "prereq_code", "field"))
  logic <- .read_csv(base_path(logic_file), c("course_code", "field", "raw_text", "logic_tree"))
  special <- .empty_table(c("review_id", "course_code", "field", "raw_text", "note"))
  keys <- paste(template$course_code, template$field, sep = "|")
  edges <- edges[!paste(edges$course_code, edges$field, sep = "|") %in% keys, , drop = FALSE]
  logic <- logic[!paste(logic$course_code, logic$field, sep = "|") %in% keys, , drop = FALSE]
  # Validate every row before replacing any result file.
  for (i in seq_len(nrow(template))) {
    row <- template[i, , drop = FALSE]
    if (row$status == "special") {
      if (is.na(row$note) || !nzchar(trimws(row$note))) stop("Special rules require an explanatory note (row ", i, ").", call. = FALSE)
      special <- rbind(special, row[, names(special), drop = FALSE])
      next
    }
    tree <- tryCatch(parse_prereq_expr(tokenize_prereq(row$cleaned_text)),
                     error = function(e) stop("Invalid approved expression in row ", i, ": ", conditionMessage(e), call. = FALSE))
    edges <- rbind(edges, data.frame(course_code = row$course_code,
      prereq_code = flatten_prereq_codes(tree), field = row$field))
    logic <- rbind(logic, data.frame(course_code = row$course_code, field = row$field,
      raw_text = row$raw_text, logic_tree = as.character(jsonlite::toJSON(tree, auto_unbox = TRUE))))
  }
  edges <- unique(edges)
  logic <- unique(logic)
  .write_csv(edges, edges_file)
  .write_csv(logic, logic_file)
  .write_csv(special, special_file)
  list(edges = edges, logic = logic, special_requirements = special)
}
