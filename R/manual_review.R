library(dplyr)
library(stringr)
library(tibble)
library(jsonlite)

.sourced_as_library <- TRUE
source("parse_prerequisites.R")


#'
#'
review_manually <- function(manual_review_file = "manual_review.csv",
                             output_file = "manual_review_template.csv") {
  review <- read.csv(manual_review_file, stringsAsFactors = FALSE)
  review$cleaned_text <- NA_character_
  review$note <- NA_character_

  cat("Opening data editor window. Fill in 'cleaned_text' and 'note' columns.\n")
  cat("Leave cleaned_text blank for entries that cannot be expressed as course codes.\n")
  cat("Close the editor window when done.\n")

  edited <- edit(review)

  write.csv(edited, output_file, row.names = FALSE)
  cat(sprintf("Saved to %s\n", output_file))

  edited
}


#'
#'
#'
generate_review_template <- function(manual_review_file = "manual_review.csv",
                                      output_file = "manual_review_template.csv") {
  review <- read.csv(manual_review_file, stringsAsFactors = FALSE)
  review$cleaned_text <- NA_character_
  review$note <- NA_character_

  write.csv(review, output_file, row.names = FALSE)
  cat(sprintf("Template saved to %s (%d rows to fill in)\n", output_file, nrow(review)))
  review
}


#'
#'
apply_manual_overrides <- function(template_file = "manual_review_template.csv",
                                    edges_file = "prereq_edges.csv",
                                    logic_file = "prereq_logic.csv",
                                    special_file = "special_requirements.csv") {

  template <- read.csv(template_file, stringsAsFactors = FALSE)
  edges <- read.csv(edges_file, stringsAsFactors = FALSE)
  logic <- read.csv(logic_file, stringsAsFactors = FALSE)

  special_rows <- list()
  new_edges <- list()
  new_logic <- list()

  for (i in seq_len(nrow(template))) {
    row <- template[i, ]
    cleaned <- row$cleaned_text

    if (is.na(cleaned) || identical(str_trim(cleaned), "")) {
      special_rows[[length(special_rows) + 1]] <- tibble(
        course_code = row$course_code, field = row$field,
        raw_text = row$raw_text, note = row$note
      )
      next
    }

    if (!is_clean_prereq(cleaned)) {
      stop(sprintf(
        "Row %d (%s / %s): cleaned_text still contains free text, please simplify further: %s",
        i, row$course_code, row$field, cleaned
      ))
    }

    tree <- parse_prereq_expr(tokenize_prereq(cleaned))
    codes <- unique(flatten_prereq_codes(tree))
    tree_json <- as.character(toJSON(tree, auto_unbox = TRUE))

    new_logic[[length(new_logic) + 1]] <- tibble(
      course_code = row$course_code, field = row$field,
      raw_text = row$raw_text, logic_tree = tree_json
    )

    for (code in codes) {
      new_edges[[length(new_edges) + 1]] <- tibble(
        course_code = row$course_code, prereq_code = code, field = row$field
      )
    }
  }

  edges <- bind_rows(edges, bind_rows(new_edges))
  logic <- bind_rows(logic, bind_rows(new_logic))
  special <- bind_rows(special_rows)

  write.csv(edges, edges_file, row.names = FALSE)
  write.csv(logic, logic_file, row.names = FALSE)
  write.csv(special, special_file, row.names = FALSE)

  cat(sprintf("Merged %d manually-cleaned entries into edges/logic\n", length(new_logic)))
  cat(sprintf("Archived %d entries to %s as non-course requirements\n", nrow(special), special_file))
}

