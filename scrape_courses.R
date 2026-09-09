library(chromote)
library(rvest)
library(dplyr)
library(stringr)
library(httr)

USER_AGENT <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

#' 抓取 UQ 专业课程列表
#'
#' @param url 目标专业 plan 页面 URL
#' @param output_file 输出 csv 文件名
#' @return 包含 course_code 列的 data.frame
fetch_program_courses <- function(url, output_file = "courses_info.csv") {
  
  b <- ChromoteSession$new()
  
  # 伪装 UA,避开针对 HeadlessChrome 的 403 拦截
  b$Network$enable()
  b$Network$setUserAgentOverride(
    userAgent = USER_AGENT
  )
  
  b$Page$navigate(url)
  b$Page$loadEventFired(timeout_ = 30)
  
  # 等待 JS 渲染完成
  Sys.sleep(3)
  
  rendered_html <- b$Runtime$evaluate("document.documentElement.outerHTML")$result$value
  b$close()
  
  page <- read_html(rendered_html)
  
  course_codes <- page %>%
    html_elements(".curriculum-reference__code") %>%
    html_text2()
  
  cat(sprintf("Extracted %d records\n", length(course_codes), length(course_codes)))
  
  courses_info <- data.frame(course_code = course_codes)
  write.csv(courses_info, output_file, row.names = FALSE)
  
  cat(sprintf("Saved to %s\n", output_file, output_file))
  
  courses_info
}

#' 从单个课程详情页提取字段
#'
#' @param page 用 read_html() 解析好的 rvest 页面对象
#' @return 单行 tibble,包含 course_name、course_level、faculty、school、
#'   units、duration、class_hours、incompatible、prerequisite、
#'   recommended_prerequisite、assessment_methods
extract_course_info <- function(page) {
  
  get_field <- function(id) {
    node <- page %>% html_element(paste0("#", id))
    if (is.na(node) || is.null(node)) return(NA_character_)
    
    txt <- html_text2(node)
    
    if (identical(txt, "")) {
      sib <- node %>% html_element(xpath = "following-sibling::p[1]")
      if (!is.na(sib) && !is.null(sib)) txt <- html_text2(sib)
    }
    
    if (identical(txt, "")) txt <- NA_character_
    
    str_replace_all(txt, "\n", "; ")
  }
  
  title_raw <- page %>% html_element("#course-title") %>% html_text2()
  course_name <- str_remove(title_raw, "\\s*\\([A-Z]{4}\\d{4}\\)\\s*$") %>% str_squish()
  
  tibble(
    course_name = course_name,
    course_level = get_field("course-level"),
    faculty = get_field("course-faculty"),
    school = get_field("course-school"),
    units = get_field("course-units"),
    duration = get_field("course-duration"),
    class_hours = get_field("course-contact"),
    incompatible = get_field("course-incompatible"),
    prerequisite  = get_field("course-prerequisite"),
    recommended_prerequisite = get_field("course-recommended-prerequisite"),
    assessment_methods = get_field("course-assessment-methods")
  )
}


#' 批量抓取课程详情并写入 csv
#'
#' @param course_codes 课程代码向量
#' @param output_file 输出 csv 文件名
#' @param delay 每次请求间隔秒数
#' @return 包含所有课程详情的 data.frame
fetch_course_details <- function(course_codes, output_file = "courses_info.csv", delay = 1) {
  
  results <- vector("list", length(course_codes))
  
  for (i in seq_along(course_codes)) {
    code <- course_codes[i]
    url <- paste0("https://programs-courses.uq.edu.au/course.html?course_code=", code)
    
    result <- tryCatch({
      resp <- GET(url, user_agent(USER_AGENT), timeout(15))
      if (status_code(resp) != 200) stop(paste("status", status_code(resp)))
      
      page <- read_html(resp)
      info <- extract_course_info(page)
      info$course_code <- code
      
      cat(sprintf("[%d/%d] %s: success\n", i, length(course_codes), code))
      info
      
    }, error = function(e) {
      cat(sprintf("[%d/%d] %s: failed - %s\n", i, length(course_codes), code, conditionMessage(e)))
      tibble(course_code = code)
    })
    
    results[[i]] <- result
    Sys.sleep(delay)
  }
  
  final_df <- bind_rows(results) %>% relocate(course_code, .before = 1)
  
  write.csv(final_df, output_file, row.names = FALSE)
  cat(sprintf("Saved to %s\n", output_file))
  
  final_df
}

# 调用函数
courses_info <- fetch_program_courses(
  url = "https://programs-courses.uq.edu.au/requirements/plan/ELECEX2350/2026",
  output_file = "courses_info.csv"
)

print(courses_info)

course_details <- fetch_course_details(
  course_codes = unique(courses_info$course_code),
  output_file = "courses_info.csv"
)

print(course_details)