# Stage 1: scrape UQ data

```r
run_stage("scrape", config)
```

The requirements page is rendered through Chrome. The scraper waits for course elements and closes its browser session on success or failure. Course detail pages use HTTP requests with your configured timeout, user agent, delay, and retry limit.

Each attempted course is saved immediately. Inspect `fetch_status`, `error`, `attempts`, `source_url`, `academic_year`, and `retrieved_at` in `courses_info.csv`. Successful rows are reused only for the same source URL and requested year. Failed rows retry next time; old rows lacking provenance are downloaded again. Changing the requested code list removes unrelated cached rows from that source file.

```r
# Refresh successful records as well as failed ones:
run_stage("scrape", config, refresh = TRUE)
```

A partial scrape is useful diagnostic evidence, but the managed pipeline refuses to parse it. Check failures and rerun collection. A recorded requested year does not independently verify UQ's historical content; inspect the returned official pages when year-specific accuracy matters.

See [configuration](../configuration.md) and the [scraping reference](../reference/scraping.md).
