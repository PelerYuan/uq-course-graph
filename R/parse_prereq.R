# Lexical validation is separate from grammar validation.
#' Check prerequisite vocabulary
#'
#' Checks lexical support only. A TRUE result does not guarantee valid grammar; use tokenize_prereq() and parse_prereq_expr() to validate a complete expression.
#'
#' @param text One non-missing prerequisite expression string. Only explicit course codes, AND, OR, and parentheses are parsed automatically.
#' @return A single logical value.
#' @export
is_clean_prereq <- function(text) {
  if (!is.character(text) || length(text) != 1L || is.na(text) || !nzchar(trimws(text))) return(FALSE)
  text <- sub("[.;]\\s*$", "", text)
  remainder <- gsub("[A-Z]{4}[0-9]{4}", "", text)
  remainder <- gsub("\\b(and|or)\\b", "", remainder, ignore.case = TRUE)
  !nzchar(gsub("[(),[:space:]]", "", remainder))
}
#' Tokenize a prerequisite expression
#'
#' Rejects free text and ambiguous bare commas. Explicit comma-and or comma-or conjunctions are accepted, as is one trailing period or semicolon.
#'
#' @param text One non-missing prerequisite expression string. Only explicit course codes, AND, OR, and parentheses are parsed automatically.
#' @return A character vector of course codes, operators, and parentheses.
#' @export
tokenize_prereq <- function(text) {
  if (!is_clean_prereq(text)) stop("Unsupported prerequisite text; manual review is required.", call. = FALSE)
  text <- sub("[.;]\\s*$", "", text)
  text <- gsub(",\\s*(and|or)\\b", " \\1 ", text, ignore.case = TRUE)
  if (grepl(",", text, fixed = TRUE)) stop("Ambiguous comma; replace it with explicit AND or OR after review.", call. = FALSE)
  tokens <- regmatches(text, gregexpr("\\(|\\)|[A-Z]{4}[0-9]{4}|(?i)\\b(?:and|or)\\b", text, perl = TRUE))[[1]]
  ifelse(grepl("^[A-Z]{4}[0-9]{4}$", tokens), tokens, tolower(tokens))
}
#' Parse prerequisite logic
#'
#' Uses AND precedence over OR and supports nested parentheses. Rejects missing operands, unbalanced parentheses, unsupported tokens, and trailing tokens.
#'
#' @param tokens Character vector returned by tokenize_prereq().
#' @return A course-code string or nested list with op and args. Errors never return partial trees.
#' @export
#' @examples
#' parse_prereq_expr(tokenize_prereq("CSSE1001 and (MATH1051 or MATH1071)"))
parse_prereq_expr <- function(tokens) {
  if (!is.character(tokens) || !length(tokens) || anyNA(tokens)) stop("Expected prerequisite tokens.", call. = FALSE)
  pos <- 1L
  peek <- function() if (pos <= length(tokens)) tokens[[pos]] else NA_character_
  advance <- function() pos <<- pos + 1L
  factor <- function() {
    tok <- peek()
    if (identical(tok, "(")) {
      advance()
      node <- expr()
      if (!identical(peek(), ")")) stop("Expected closing parenthesis.", call. = FALSE)
      advance()
      return(node)
    }
    if (is.na(tok) || !grepl("^[A-Z]{4}[0-9]{4}$", tok))
      stop("Expected a course code at token ", pos, ".", call. = FALSE)
    advance()
    tok
  }
  term <- function() {
    args <- list(factor())
    while (identical(peek(), "and")) { advance(); args <- c(args, list(factor())) }
    if (length(args) == 1L) args[[1]] else list(op = "and", args = args)
  }
  expr <- function() {
    args <- list(term())
    while (identical(peek(), "or")) { advance(); args <- c(args, list(term())) }
    if (length(args) == 1L) args[[1]] else list(op = "or", args = args)
  }
  result <- expr()
  if (pos <= length(tokens)) stop("Unconsumed tokens remain.", call. = FALSE)
  result
}
#' Extract codes from a logic tree
#'
#' Returns the unique course-code leaves without preserving the distinction between alternatives and joint requirements.
#'
#' @param node A course-code leaf or a validated nested AND/OR logic tree.
#' @return A character vector of course codes.
#' @export
flatten_prereq_codes <- function(node) {
  if (is.character(node) && length(node) == 1L && !is.na(node) && grepl("^[A-Z]{4}[0-9]{4}$", node)) return(node)
  if (is.list(node) && length(node$op) == 1L && node$op %in% c("and", "or") && length(node$args) >= 2L)
    return(unique(unlist(lapply(node$args, flatten_prereq_codes), use.names = FALSE)))
  stop("Invalid prerequisite logic tree.", call. = FALSE)
}
#' Parse course metadata into reviewable tables
#'
#' Unsupported or malformed expressions go to manual review. Writes automatic base tables, canonical edge and logic tables, and a review queue. Re-parsing resets canonical tables; rerun review before building a graph. Empty outputs retain column headers.
#'
#' @param courses_info Data frame containing unique course_code, course_name, prerequisite, and recommended_prerequisite columns.
#' @param output_dir Directory for generated files, or the base output directory in configuration.
#' @return A list containing edges, logic, and manual_review data frames.
#' @export
parse_all_prerequisites <- function(courses_info, output_dir = ".") {
  .validate_courses(courses_info, prerequisite_columns = TRUE)
  edges <- .empty_table(c("course_code", "prereq_code", "field"))
  logic <- .empty_table(c("course_code", "field", "raw_text", "logic_tree"))
  review <- .empty_table(c("review_id", "course_code", "field", "raw_text", "reason"))
  for (i in seq_len(nrow(courses_info))) for (field in .edge_fields) {
    raw <- courses_info[[field]][i]
    if (is.na(raw) || !nzchar(trimws(raw))) next
    course <- courses_info$course_code[i]
    tree <- tryCatch(parse_prereq_expr(tokenize_prereq(raw)), error = identity)
    if (inherits(tree, "error")) {
      review <- rbind(review, data.frame(review_id = .review_ids(course, field, raw),
        course_code = course, field = field, raw_text = raw, reason = conditionMessage(tree)))
    } else {
      logic <- rbind(logic, data.frame(course_code = course, field = field, raw_text = raw,
        logic_tree = as.character(jsonlite::toJSON(tree, auto_unbox = TRUE))))
      edges <- rbind(edges, data.frame(course_code = course, prereq_code = flatten_prereq_codes(tree), field = field))
    }
  }
  edges <- unique(edges)
  for (suffix in c("", "_auto")) {
    .write_csv(edges, file.path(output_dir, paste0("prereq_edges", suffix, ".csv")))
    .write_csv(logic, file.path(output_dir, paste0("prereq_logic", suffix, ".csv")))
  }
  .write_csv(review, file.path(output_dir, "manual_review.csv"))
  message("Parsed ", nrow(logic), " expressions; ", nrow(review), " require review.")
  list(edges = edges, logic = logic, manual_review = review)
}
