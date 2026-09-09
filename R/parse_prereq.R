library(dplyr)
library(stringr)
library(tibble)
library(jsonlite)

# ============================================================
# ============================================================

#'
#'
#' @return TRUE/FALSE
is_clean_prereq <- function(text) {
  remainder <- text
  remainder <- str_remove_all(remainder, "[A-Z]{4}\\d{4}")
  remainder <- str_remove_all(remainder, regex("\\b(and|or)\\b", ignore_case = TRUE))
  remainder <- str_remove_all(remainder, "[(),.;]")
  remainder <- str_squish(remainder)
  nchar(remainder) == 0
}


# ============================================================
# ============================================================

#'
#'
tokenize_prereq <- function(text) {
  text <- str_replace_all(text, ",\\s*(?i)or\\b", " or")
  text <- str_replace_all(text, ",", " or ")

  tokens <- str_extract_all(text, "\\(|\\)|[A-Z]{4}\\d{4}|(?i)\\b(?:and|or)\\b")[[1]]

  ifelse(str_detect(tokens, "^[A-Z]{4}\\d{4}$"), tokens, str_to_lower(tokens))
}


#'
#'   expr := term ("or" term)*
#'   term := factor ("and" factor)*
#'
#'
parse_prereq_expr <- function(tokens) {
  pos <- 1
  n <- length(tokens)

  peek <- function() if (pos <= n) tokens[pos] else NA
  advance <- function() pos <<- pos + 1

  parse_factor <- function() {
    tok <- peek()
    if (identical(tok, "(")) {
      advance()
      node <- parse_expr()
      if (!identical(peek(), ")")) stop("expected closing paren")
      advance()
      return(node)
    }
    advance()
    return(tok)
  }

  parse_term <- function() {
    args <- list(parse_factor())
    while (identical(peek(), "and")) {
      advance()
      args <- c(args, list(parse_factor()))
    }
    if (length(args) == 1) return(args[[1]])
    list(op = "and", args = args)
  }

  parse_expr <- function() {
    args <- list(parse_term())
    while (identical(peek(), "or")) {
      advance()
      args <- c(args, list(parse_term()))
    }
    if (length(args) == 1) return(args[[1]])
    list(op = "or", args = args)
  }

  result <- parse_expr()
  if (pos <= n) stop("unconsumed tokens remain")
  result
}


#'
flatten_prereq_codes <- function(node) {
  if (is.character(node)) return(node)
  if (is.list(node) && !is.null(node$args)) {
    return(unlist(lapply(node$args, flatten_prereq_codes), use.names = FALSE))
  }
  character()
}


# ============================================================
# ============================================================

#'
parse_all_prerequisites <- function(courses_info, output_dir = ".") {

  edges <- list()
  logic_rows <- list()
  manual_review <- list()

  fields <- c("prerequisite", "recommended_prerequisite")

  for (i in seq_len(nrow(courses_info))) {
    course <- courses_info$course_code[i]

    for (field in fields) {
      raw <- courses_info[[field]][i]
      if (is.na(raw) || identical(str_trim(raw), "")) next

      if (!is_clean_prereq(raw)) {
        manual_review[[length(manual_review) + 1]] <- tibble(
          course_code = course, field = field, raw_text = raw, reason = "contains_free_text"
        )
        next
      }

      tree <- tryCatch(
        parse_prereq_expr(tokenize_prereq(raw)),
        error = function(e) e
      )

      if (inherits(tree, "error")) {
        manual_review[[length(manual_review) + 1]] <- tibble(
          course_code = course, field = field, raw_text = raw,
          reason = paste("parse_error:", conditionMessage(tree))
        )
        next
      }

      codes <- unique(flatten_prereq_codes(tree))
      tree_json <- as.character(toJSON(tree, auto_unbox = TRUE))

      logic_rows[[length(logic_rows) + 1]] <- tibble(
        course_code = course, field = field,
        raw_text = raw, logic_tree = tree_json
      )

      for (code in codes) {
        edges[[length(edges) + 1]] <- tibble(
          course_code = course, prereq_code = code, field = field
        )
      }
    }
  }

  edges_df <- bind_rows(edges)
  logic_df <- bind_rows(logic_rows)
  manual_review_df <- bind_rows(manual_review)

  write.csv(edges_df, file.path(output_dir, "prereq_edges.csv"), row.names = FALSE)
  write.csv(logic_df, file.path(output_dir, "prereq_logic.csv"), row.names = FALSE)
  write.csv(manual_review_df, file.path(output_dir, "manual_review.csv"), row.names = FALSE)

  cat(sprintf(
    "Parsed %d entries successfully, %d flagged for manual review\n",
    nrow(logic_df), nrow(manual_review_df)
  ))
  cat(sprintf("Edges: %d, saved to prereq_edges.csv\n", nrow(edges_df)))
  cat("Logic trees saved to prereq_logic.csv\n")
  cat("Manual review items saved to manual_review.csv\n")

  list(edges = edges_df, logic = logic_df, manual_review = manual_review_df)
}

