

PALETTE_MAIN <- "#42a5f5"
PALETTE_ACCENT <- "#d84315"
THEME_BASE <- ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(face = "bold", size = 13),
    plot.subtitle = ggplot2::element_text(colour = "#607d8b", size = 9)
  )

#' Plot gateway course rankings
#'
#' Plots the first top_n rows of a ranking produced by rank_key_courses().
#'
#' @param key_courses_file Ranking CSV produced by rank_key_courses(), sorted by downstream reach.
#' @param top_n Positive integer number of ranking rows to plot.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return A ggplot object invisibly; also saves a PNG.
#' @export
plot_key_courses <- function(key_courses_file = "key_courses.csv",
                              top_n = 15,
                              output_file = "stat_key_courses.png") {
  .number_scalar(top_n, "top_n", 1, integer = TRUE)
  df <- utils::read.csv(key_courses_file, stringsAsFactors = FALSE) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(course_code = factor(course_code, levels = rev(course_code)))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = downstream_count, y = course_code)) +
    ggplot2::geom_col(fill = PALETTE_MAIN, width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = downstream_count), hjust = -0.3, size = 3, colour = "#455a64") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(
      title = sprintf("Top %d Gateway Courses", top_n),
      subtitle = "Number of downstream courses reachable through the prerequisite chain",
      x = "Downstream courses unlocked", y = NULL
    ) +
    THEME_BASE

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = 7, height = 5, dpi = 300)
  .plot_manifest(output_file, provenance = .fingerprints(c(key_courses_file)), options = list(function_name = "plot_key_courses"))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

#' Plot discipline and level counts
#'
#' Counts supplied course rows by four-letter prefix and fifth-character code level. This level does not determine the scheduled year of study.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return A ggplot object invisibly; also saves a PNG.
#' @export
plot_prefix_by_level <- function(courses_file = "courses_info.csv",
                                  output_file = "stat_prefix_by_level.png") {
  df <- utils::read.csv(courses_file, stringsAsFactors = FALSE) |>
    dplyr::mutate(
      prefix = substr(course_code, 1, 4),
      year_level = substr(course_code, 5, 5)
    ) |>
    dplyr::count(prefix, year_level) |>
    dplyr::group_by(prefix) |>
    dplyr::mutate(total = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::mutate(prefix = stats::reorder(prefix, total))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = n, y = prefix, fill = year_level)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_brewer(palette = "Blues", name = "Level") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.05))) +
    ggplot2::labs(
      title = "Course Count by Discipline and Year Level",
      subtitle = "Level taken from the 5th character of the course code",
      x = "Number of courses", y = NULL
    ) +
    THEME_BASE

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = 7, height = 5, dpi = 300)
  .plot_manifest(output_file, provenance = .fingerprints(c(courses_file)), options = list(function_name = "plot_prefix_by_level"))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

#' Plot listed prerequisite counts
#'
#' Counts prerequisite edges by course level. OR alternatives are counted separately, so this is a descriptive measure, not required workload.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param edges_file Path to a CSV containing course_code, prereq_code, and field.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return A ggplot object invisibly; also saves a PNG.
#' @export
plot_prereq_count_by_level <- function(courses_file = "courses_info.csv",
                                        edges_file = "prereq_edges.csv",
                                        output_file = "stat_prereq_by_level.png") {
  courses <- utils::read.csv(courses_file, stringsAsFactors = FALSE)
  edges <- utils::read.csv(edges_file, stringsAsFactors = FALSE) |>
    dplyr::filter(field == "prerequisite")

  prereq_count <- edges |> dplyr::count(course_code, name = "n_prereq")

  df <- courses |>
    dplyr::left_join(prereq_count, by = "course_code") |>
    dplyr::mutate(
      n_prereq = dplyr::coalesce(n_prereq, 0L),
      year_level = substr(course_code, 5, 5)
    ) |>
    dplyr::filter(year_level %in% c("1", "2", "3", "4"))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = year_level, y = n_prereq)) +
    ggplot2::geom_boxplot(fill = PALETTE_MAIN, alpha = 0.35, outlier.shape = NA, width = 0.5) +
    ggplot2::geom_jitter(width = 0.15, height = 0, size = 1.8, alpha = 0.6, colour = "#455a64") +
    ggplot2::labs(
      title = "Prerequisite Load Across Year Levels",
      subtitle = "Each dot is a course; OR-alternatives are counted separately",
      x = "Year level", y = "Number of prerequisite courses listed"
    ) +
    THEME_BASE

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = 6.5, height = 4.5, dpi = 300)
  .plot_manifest(output_file, provenance = .fingerprints(c(courses_file, edges_file)), options = list(function_name = "plot_prereq_count_by_level"))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

#' Summarize weekly contact hours
#'
#' Parses weekly activity descriptions and sums their hours. Missing or unsupported descriptions are omitted.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return A ggplot object invisibly; also saves a PNG.
#' @export
plot_class_hours <- function(courses_file = "courses_info.csv",
                              output_file = "stat_class_hours.png") {
  courses <- utils::read.csv(courses_file, stringsAsFactors = FALSE)

  parsed <- courses |>
    dplyr::filter(!is.na(class_hours)) |>
    dplyr::select(course_code, class_hours) |>
    tidyr::separate_rows(class_hours, sep = ";") |>
    dplyr::mutate(
      activity = stringr::str_extract(stringr::str_trim(class_hours), "^[A-Za-z ]+?(?=\\s+[\\d.])"),
      hours = as.numeric(stringr::str_extract(class_hours, "[\\d.]+(?=\\s*Hours?)")),
      per_week = stringr::str_detect(class_hours, stringr::regex("Week", ignore_case = TRUE))
    ) |>
    dplyr::filter(!is.na(activity), !is.na(hours), per_week) |>
    dplyr::mutate(activity = stringr::str_trim(activity))

  summary_df <- parsed |>
    dplyr::group_by(activity) |>
    dplyr::summarise(total_hours = sum(hours), n_courses = dplyr::n(), .groups = "drop") |>
    dplyr::mutate(activity = stats::reorder(activity, total_hours))

  p <- ggplot2::ggplot(summary_df, ggplot2::aes(x = total_hours, y = activity)) +
    ggplot2::geom_col(fill = PALETTE_MAIN, width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%g h (%d courses)", total_hours, n_courses)),
              hjust = -0.1, size = 2.8, colour = "#455a64") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.25))) +
    ggplot2::labs(
      title = "Weekly Contact Hours by Activity Type",
      subtitle = "Summed across the available weekly activity descriptions",
      x = "Total hours per week (all courses combined)", y = NULL
    ) +
    THEME_BASE

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = 7.5, height = 4.5, dpi = 300)
  .plot_manifest(output_file, provenance = .fingerprints(c(courses_file)), options = list(function_name = "plot_class_hours"))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

#' Summarize assessment keywords
#'
#' Counts courses mentioning each assessment keyword. Categories overlap, so percentages need not sum to 100.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param output_file Output file path. Parent directories are created when needed.
#' @return A ggplot object invisibly; also saves a PNG.
#' @export
plot_assessment_mix <- function(courses_file = "courses_info.csv",
                                 output_file = "stat_assessment_mix.png") {
  courses <- utils::read.csv(courses_file, stringsAsFactors = FALSE) |>
    dplyr::filter(!is.na(assessment_methods))

  keywords <- c(
    Exam = "exam",
    Assignment = "assignment",
    Project = "project",
    Practical = "practical|laborator",
    Quiz = "quiz|class test",
    Presentation = "presentation",
    Report = "report",
    Tutorial = "tutorial"
  )

  counts <- sapply(keywords, function(kw) {
    sum(stringr::str_detect(courses$assessment_methods, stringr::regex(kw, ignore_case = TRUE)))
  })

  df <- tibble::tibble(
    method = names(counts),
    n_courses = as.integer(counts)
  ) |>
    dplyr::mutate(
      pct = n_courses / nrow(courses),
      method = stats::reorder(method, n_courses)
    )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = pct, y = method)) +
    ggplot2::geom_col(fill = PALETTE_MAIN, width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%d (%.0f%%)", n_courses, pct * 100)),
              hjust = -0.15, size = 2.9, colour = "#455a64") +
    ggplot2::scale_x_continuous(labels = scales::percent, expand = ggplot2::expansion(mult = c(0, 0.2))) +
    ggplot2::labs(
      title = "Assessment Methods Across the Program",
      subtitle = sprintf("Keyword matched in course descriptions (n = %d courses)", nrow(courses)),
      x = "Share of courses using this method", y = NULL
    ) +
    THEME_BASE

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = 7, height = 4.5, dpi = 300)
  .plot_manifest(output_file, provenance = .fingerprints(c(courses_file)), options = list(function_name = "plot_assessment_mix"))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

