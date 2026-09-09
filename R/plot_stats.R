library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)


PALETTE_MAIN <- "#42a5f5"
PALETTE_ACCENT <- "#d84315"
THEME_BASE <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "#607d8b", size = 9)
  )


#'
#'
plot_key_courses <- function(key_courses_file = "key_courses.csv",
                              top_n = 15,
                              output_file = "stat_key_courses.png") {
  df <- read.csv(key_courses_file, stringsAsFactors = FALSE) %>%
    slice_head(n = top_n) %>%
    mutate(course_code = factor(course_code, levels = rev(course_code)))

  p <- ggplot(df, aes(x = downstream_count, y = course_code)) +
    geom_col(fill = PALETTE_MAIN, width = 0.7) +
    geom_text(aes(label = downstream_count), hjust = -0.3, size = 3, colour = "#455a64") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
    labs(
      title = sprintf("Top %d Gateway Courses", top_n),
      subtitle = "Number of downstream courses reachable through the prerequisite chain",
      x = "Downstream courses unlocked", y = NULL
    ) +
    THEME_BASE

  ggsave(output_file, p, width = 7, height = 5, dpi = 300)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}


#'
#'
#' @param courses_file courses_info.csv
plot_prefix_by_level <- function(courses_file = "courses_info.csv",
                                  output_file = "stat_prefix_by_level.png") {
  df <- read.csv(courses_file, stringsAsFactors = FALSE) %>%
    mutate(
      prefix = substr(course_code, 1, 4),
      year_level = substr(course_code, 5, 5)
    ) %>%
    count(prefix, year_level) %>%
    group_by(prefix) %>%
    mutate(total = sum(n)) %>%
    ungroup() %>%
    mutate(prefix = reorder(prefix, total))

  p <- ggplot(df, aes(x = n, y = prefix, fill = year_level)) +
    geom_col(width = 0.7) +
    scale_fill_brewer(palette = "Blues", name = "Level") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(
      title = "Course Count by Discipline and Year Level",
      subtitle = "Level taken from the 5th character of the course code",
      x = "Number of courses", y = NULL
    ) +
    THEME_BASE

  ggsave(output_file, p, width = 7, height = 5, dpi = 300)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}


#'
#'
#' @param courses_file courses_info.csv
#' @param edges_file prereq_edges.csv
plot_prereq_count_by_level <- function(courses_file = "courses_info.csv",
                                        edges_file = "prereq_edges.csv",
                                        output_file = "stat_prereq_by_level.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE)
  edges <- read.csv(edges_file, stringsAsFactors = FALSE) %>%
    filter(field == "prerequisite")

  prereq_count <- edges %>% count(course_code, name = "n_prereq")

  df <- courses %>%
    left_join(prereq_count, by = "course_code") %>%
    mutate(
      n_prereq = coalesce(n_prereq, 0L),
      year_level = substr(course_code, 5, 5)
    ) %>%
    filter(year_level %in% c("1", "2", "3", "4"))

  p <- ggplot(df, aes(x = year_level, y = n_prereq)) +
    geom_boxplot(fill = PALETTE_MAIN, alpha = 0.35, outlier.shape = NA, width = 0.5) +
    geom_jitter(width = 0.15, height = 0, size = 1.8, alpha = 0.6, colour = "#455a64") +
    labs(
      title = "Prerequisite Load Across Year Levels",
      subtitle = "Each dot is a course; OR-alternatives are counted separately",
      x = "Year level", y = "Number of prerequisite courses listed"
    ) +
    THEME_BASE

  ggsave(output_file, p, width = 6.5, height = 4.5, dpi = 300)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}


#'
#'
#' @param courses_file courses_info.csv
plot_class_hours <- function(courses_file = "courses_info.csv",
                              output_file = "stat_class_hours.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE)

  parsed <- courses %>%
    filter(!is.na(class_hours)) %>%
    select(course_code, class_hours) %>%
    separate_rows(class_hours, sep = ";") %>%
    mutate(
      activity = str_extract(str_trim(class_hours), "^[A-Za-z ]+?(?=\\s+[\\d.])"),
      hours = as.numeric(str_extract(class_hours, "[\\d.]+(?=\\s*Hours?)")),
      per_week = str_detect(class_hours, regex("Week", ignore_case = TRUE))
    ) %>%
    filter(!is.na(activity), !is.na(hours), per_week) %>%
    mutate(activity = str_trim(activity))

  summary_df <- parsed %>%
    group_by(activity) %>%
    summarise(total_hours = sum(hours), n_courses = n(), .groups = "drop") %>%
    mutate(activity = reorder(activity, total_hours))

  p <- ggplot(summary_df, aes(x = total_hours, y = activity)) +
    geom_col(fill = PALETTE_MAIN, width = 0.7) +
    geom_text(aes(label = sprintf("%g h (%d courses)", total_hours, n_courses)),
              hjust = -0.1, size = 2.8, colour = "#455a64") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
    labs(
      title = "Weekly Contact Hours by Activity Type",
      subtitle = "Summed across all courses; activity types appearing in only one course omitted",
      x = "Total hours per week (all courses combined)", y = NULL
    ) +
    THEME_BASE

  ggsave(output_file, p, width = 7.5, height = 4.5, dpi = 300)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}


#'
#'
#' @param courses_file courses_info.csv
plot_assessment_mix <- function(courses_file = "courses_info.csv",
                                 output_file = "stat_assessment_mix.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE) %>%
    filter(!is.na(assessment_methods))

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
    sum(str_detect(courses$assessment_methods, regex(kw, ignore_case = TRUE)))
  })

  df <- tibble(
    method = names(counts),
    n_courses = as.integer(counts)
  ) %>%
    mutate(
      pct = n_courses / nrow(courses),
      method = reorder(method, n_courses)
    )

  p <- ggplot(df, aes(x = pct, y = method)) +
    geom_col(fill = PALETTE_MAIN, width = 0.7) +
    geom_text(aes(label = sprintf("%d (%.0f%%)", n_courses, pct * 100)),
              hjust = -0.15, size = 2.9, colour = "#455a64") +
    scale_x_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.2))) +
    labs(
      title = "Assessment Methods Across the Program",
      subtitle = sprintf("Keyword matched in course descriptions (n = %d courses)", nrow(courses)),
      x = "Share of courses using this method", y = NULL
    ) +
    THEME_BASE

  ggsave(output_file, p, width = 7, height = 4.5, dpi = 300)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

