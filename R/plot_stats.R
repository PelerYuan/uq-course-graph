library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)


# 统一配色,跟依赖图那边保持一致的视觉语言
PALETTE_MAIN <- "#42a5f5"
PALETTE_ACCENT <- "#d84315"
THEME_BASE <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "#607d8b", size = 9)
  )


#' 图A: 关键课程排行榜
#'
#' downstream_count = 顺着依赖链能解锁的下游课程总数,
#' 这个数字比"直接前置了几门课"更能反映一门课的地基程度
#'
#' @param key_courses_file build_graph.R 生成的 key_courses.csv
#' @param top_n 显示前几名
#' @param output_file 输出路径
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


#' 图B: 各学科课程数量分布(按年级堆叠)
#'
#' 课程代码第5位数字就是年级(CSSE2310 -> 2年级),
#' 堆叠柱状图能同时看出"哪个学科课多"和"这些课集中在哪个年级"
#'
#' @param courses_file courses_info.csv
#' @param output_file 输出路径
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


#' 图C: 前置课程数量 vs 年级
#'
#' 检验一个直觉假设:年级越高的课,前置要求是不是越多?
#' 用箱线图能同时看出中位数和离散程度,比单纯画平均值信息量大
#'
#' @param courses_file courses_info.csv
#' @param edges_file prereq_edges.csv
#' @param output_file 输出路径
plot_prereq_count_by_level <- function(courses_file = "courses_info.csv",
                                        edges_file = "prereq_edges.csv",
                                        output_file = "stat_prereq_by_level.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE)
  edges <- read.csv(edges_file, stringsAsFactors = FALSE) %>%
    filter(field == "prerequisite")

  # 每门课被列出的前置课程数(注意 OR 关系会让这个数字偏大,
  # 比如 "A or B" 算2门,但实际只需修其中1门——这是拍平边表的固有局限)
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


#' 图D: 每周课时构成
#'
#' 从 class_hours 文本里解析出各类课时(Lecture/Practical/Tutorial 等),
#' 看整个专业的教学时间是怎么分配的
#'
#' @param courses_file courses_info.csv
#' @param output_file 输出路径
plot_class_hours <- function(courses_file = "courses_info.csv",
                              output_file = "stat_class_hours.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE)

  # class_hours 格式形如 "Lecture 2 Hours/ Week; Practical 4 Hours/ Week"
  # 按分号拆开,再提取"类型 + 小时数",只保留按周计的部分
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
    filter(n_courses >= 2) %>%    # 只出现1次的活动类型没有统计意义
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


#' 图E: 考核方式构成
#'
#' 从 assessment_methods 文本里匹配常见考核关键词,
#' 看这个专业整体是偏考试还是偏作业/项目
#'
#' @param courses_file courses_info.csv
#' @param output_file 输出路径
plot_assessment_mix <- function(courses_file = "courses_info.csv",
                                 output_file = "stat_assessment_mix.png") {
  courses <- read.csv(courses_file, stringsAsFactors = FALSE) %>%
    filter(!is.na(assessment_methods))

  # 用关键词匹配而不是精确切分,因为这个字段是自由文本、写法很不统一
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

