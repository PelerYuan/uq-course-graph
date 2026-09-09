# Stage 1: scrape UQ data

## Why two request methods are used

The requirements page renders course codes with JavaScript, so `fetch_program_courses()` uses `chromote` and overrides the default headless User-Agent. Individual course pages are static, so `fetch_course_details()` uses `httr` and `rvest`.

## Run

```r
source("01_scrape.R")
```

## Outputs

- `data/course_codes.csv`: discovered course codes;
- `data/courses_info.csv`: one row per course;
- console messages for successful and failed requests.

## Safe reruns

Existing course codes are skipped. This makes it safe to rerun after a network interruption. Failed codes can be retried without redownloading successful rows.

## Failure messages

An empty rendered course list stops the stage. Check Chrome, the route type, the code, and the year. A single failed detail page is recorded while the other courses continue.
