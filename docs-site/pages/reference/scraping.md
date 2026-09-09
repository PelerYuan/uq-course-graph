# Scraping reference

## `fetch_program_courses(url, output_file)`

Renders a plan or program URL with Chrome and returns a data frame containing `course_code`. It stops if the rendered selector produces zero codes.

## `extract_course_info(page)`

Extracts fields from an `rvest` HTML document for one course page.

## `fetch_course_details(course_codes, output_file, delay)`

Fetches static course pages, skips course codes already present in the output, and records per-course failures in the console.
