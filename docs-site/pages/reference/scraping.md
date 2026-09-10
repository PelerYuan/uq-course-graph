# Scraping reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `fetch_program_courses()`

Requires the optional chromote package and Chrome. Waits for rendered course elements and closes its browser session even on failure. Records the source URL and retrieval time.

```r
fetch_program_courses (url, output_file = "course_codes.csv", timeout = 30,
    user_agent = "uqcoursegraph/0.2.0", poll_interval = 0.5)
```

| Argument | Meaning |
| --- | --- |
| `url` | Public UQ requirements URL to render with Chrome. |
| `output_file` | Output file path. Parent directories are created when needed. |
| `timeout` | Positive request timeout in seconds. |
| `user_agent` | Non-empty User-Agent string sent with requests. |
| `poll_interval` | Positive interval in seconds for checking rendered course elements. |

**Returns:** A data frame with course_code, source_url, and retrieved_at.

## `extract_course_info()`

Reads supported UQ page fields and fails if the course title is missing. An absent optional field remains NA; page layouts can change.

```r
extract_course_info (page)
```

| Argument | Meaning |
| --- | --- |
| `page` | Parsed HTML document returned by rvest::read_html(). |

**Returns:** A one-row metadata data frame.

## `fetch_course_details()`

Persists each attempted course with status, source URL, requested year, timestamp, attempt count, and error. Only successful rows for the same URL and year are reused. Failed or legacy rows retry on the next run. The requested year is not independent verification that the server served an archived page.

```r
fetch_course_details (course_codes, output_file = "courses_info.csv", delay = 1,
    timeout = 30, retries = 2, academic_year = NULL, user_agent = "uqcoursegraph/0.2.0",
    refresh = FALSE)
```

| Argument | Meaning |
| --- | --- |
| `course_codes` | Character vector of valid uppercase course codes to download. |
| `output_file` | Output file path. Parent directories are created when needed. |
| `delay` | Non-negative delay in seconds between requests. Retries use exponential backoff. |
| `timeout` | Positive request timeout in seconds. |
| `retries` | Non-negative integer number of retries after the initial attempt. |
| `academic_year` | Integer requested catalogue year. In fetch_course_details(), NULL requests the current page. |
| `user_agent` | Non-empty User-Agent string sent with requests. |
| `refresh` | Logical; TRUE downloads successful cached records again. |

**Returns:** A data frame in requested code order, including failed rows for inspection. Failed rows must be resolved before parsing.
