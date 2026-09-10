#' Collect rendered requirements course codes
#'
#' Requires the optional chromote package and Chrome. Waits for rendered course elements and closes its browser session even on failure. Records the source URL and retrieval time.
#'
#' @param url Public UQ requirements URL to render with Chrome.
#' @param output_file Output file path. Parent directories are created when needed.
#' @param timeout Positive request timeout in seconds.
#' @param user_agent Non-empty User-Agent string sent with requests.
#' @param poll_interval Positive interval in seconds for checking rendered course elements.
#' @return A data frame with course_code, source_url, and retrieved_at.
#' @export
fetch_program_courses <- function(url, output_file = "course_codes.csv", timeout = 30,
                                  user_agent = "uqcoursegraph/0.2.0", poll_interval = 0.5) {
  .text_scalar(url, "url")
  .number_scalar(timeout, "timeout", 0.1)
  .number_scalar(poll_interval, "poll_interval", 0.01)
  if (!requireNamespace("chromote", quietly = TRUE))
    stop("Install chromote and Chrome to scrape a requirements page.", call. = FALSE)
  browser <- chromote::ChromoteSession$new()
  on.exit(try(browser$close(), silent = TRUE), add = TRUE)
  browser$Network$enable()
  browser$Network$setUserAgentOverride(userAgent = user_agent)
  browser$Page$navigate(url, timeout_ = timeout)
  deadline <- Sys.time() + timeout
  repeat {
    html <- browser$Runtime$evaluate("document.documentElement.outerHTML", timeout_ = timeout)$result$value
    page <- rvest::read_html(html)
    codes <- unique(trimws(rvest::html_text2(rvest::html_elements(page, ".curriculum-reference__code"))))
    codes <- codes[grepl("^[A-Z]{4}[0-9]{4}$", codes)]
    if (length(codes)) break
    if (Sys.time() >= deadline) stop("No course codes appeared before timeout; check the requirements URL or page structure.", call. = FALSE)
    Sys.sleep(poll_interval)
  }
  result <- data.frame(course_code = codes, source_url = url, retrieved_at = .utc_now())
  .write_csv(result, output_file)
  result
}

#' Extract one course page
#'
#' Reads supported UQ page fields and fails if the course title is missing. An absent optional field remains NA; page layouts can change.
#'
#' @param page Parsed HTML document returned by rvest::read_html().
#' @return A one-row metadata data frame.
#' @export
extract_course_info <- function(page) {
  get_field <- function(id) {
    node <- rvest::html_element(page, paste0("#", id))
    if (is.na(node)) return(NA_character_)
    txt <- rvest::html_text2(node)
    if (!nzchar(trimws(txt))) {
      sib <- rvest::html_element(node, xpath = "following-sibling::p[1]")
      if (!is.na(sib)) txt <- rvest::html_text2(sib)
    }
    if (is.na(txt) || !nzchar(trimws(txt))) return(NA_character_)
    gsub("\n", "; ", txt, fixed = TRUE)
  }
  title <- rvest::html_text2(rvest::html_element(page, "#course-title"))
  name <- trimws(sub("\\s*\\([A-Z]{4}[0-9]{4}\\)\\s*$", "", title))
  if (is.na(name) || !nzchar(name)) stop("Course title is missing; the page may be an error page or its structure changed.", call. = FALSE)
  data.frame(course_name = name, course_level = get_field("course-level"),
    faculty = get_field("course-faculty"), school = get_field("course-school"),
    units = get_field("course-units"), duration = get_field("course-duration"),
    class_hours = get_field("course-contact"), incompatible = get_field("course-incompatible"),
    prerequisite = get_field("course-prerequisite"),
    recommended_prerequisite = get_field("course-recommended-prerequisite"),
    assessment_methods = get_field("course-assessment-methods"))
}

.request_html <- function(url, timeout, user_agent) {
  response <- httr::GET(url, httr::user_agent(user_agent), httr::timeout(timeout))
  httr::stop_for_status(response)
  httr::content(response, as = "text", encoding = "UTF-8")
}

#' Download resumable course metadata
#'
#' Persists each attempted course with status, source URL, requested year, timestamp, attempt count, and error. Only successful rows for the same URL and year are reused. Failed or legacy rows retry on the next run. The requested year is not independent verification that the server served an archived page.
#'
#' @param course_codes Character vector of valid uppercase course codes to download.
#' @param output_file Output file path. Parent directories are created when needed.
#' @param delay Non-negative delay in seconds between requests. Retries use exponential backoff.
#' @param timeout Positive request timeout in seconds.
#' @param retries Non-negative integer number of retries after the initial attempt.
#' @param academic_year Integer requested catalogue year. In fetch_course_details(), NULL requests the current page.
#' @param user_agent Non-empty User-Agent string sent with requests.
#' @param refresh Logical; TRUE downloads successful cached records again.
#' @return A data frame in requested code order, including failed rows for inspection. Failed rows must be resolved before parsing.
#' @export
fetch_course_details <- function(course_codes, output_file = "courses_info.csv", delay = 1,
                                 timeout = 30, retries = 2, academic_year = NULL,
                                 user_agent = "uqcoursegraph/0.2.0", refresh = FALSE) {
  codes <- .course_codes(course_codes, allow_empty = FALSE)
  .number_scalar(delay, "delay")
  .number_scalar(timeout, "timeout", 0.1)
  .number_scalar(retries, "retries", integer = TRUE)
  .text_scalar(user_agent, "user_agent")
  if (!is.logical(refresh) || length(refresh) != 1L || is.na(refresh)) stop("refresh must be TRUE or FALSE.", call. = FALSE)
  if (!is.null(academic_year)) .number_scalar(academic_year, "academic_year", 2000, integer = TRUE)
  year <- if (is.null(academic_year)) "current" else as.character(academic_year)
  url_for <- function(code) paste0("https://programs-courses.uq.edu.au/course.html?course_code=", code,
                                  if (is.null(academic_year)) "" else paste0("&year=", academic_year))
  result <- if (file.exists(output_file)) .read_csv(output_file, "course_code") else .empty_table("course_code")
  # Keep only this requested curriculum. Legacy caches lack provenance and are refreshed.
  result <- result[result$course_code %in% codes, , drop = FALSE]
  for (code in codes) {
    cached <- result[result$course_code == code, , drop = FALSE]
    valid_cache <- all(c("fetch_status", "academic_year", "source_url", "course_name") %in% names(cached)) &&
      nrow(cached) == 1L && isTRUE(cached$fetch_status == "success") &&
      isTRUE(cached$academic_year == year) && isTRUE(cached$source_url == url_for(code)) &&
      !is.na(cached$course_name) && nzchar(cached$course_name)
    if (!refresh && valid_cache) next
    info <- NULL
    error_text <- NA_character_
    for (attempt in seq_len(retries + 1L)) {
      info <- tryCatch(extract_course_info(rvest::read_html(.request_html(url_for(code), timeout, user_agent))), error = identity)
      if (!inherits(info, "error")) break
      error_text <- conditionMessage(info)
      if (attempt <= retries) Sys.sleep(max(delay, 0.1) * 2^(attempt - 1L))
    }
    ok <- !inherits(info, "error")
    if (!ok) info <- data.frame(course_name = NA_character_, prerequisite = NA_character_, recommended_prerequisite = NA_character_)
    info$course_code <- code
    info$fetch_status <- if (ok) "success" else "failed"
    info$source_url <- url_for(code)
    info$academic_year <- year
    info$retrieved_at <- .utc_now()
    info$attempts <- as.character(attempt)
    info$error <- if (ok) NA_character_ else error_text
    result <- dplyr::bind_rows(result[result$course_code != code, , drop = FALSE], info)
    .write_csv(result, output_file)
    message(code, ": ", info$fetch_status)
    Sys.sleep(delay)
  }
  result <- result[match(codes, result$course_code), , drop = FALSE]
  .write_csv(result, output_file)
  result
}
