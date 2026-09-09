# Troubleshooting

## Chrome cannot start

Install Google Chrome and make sure it launches normally. `chromote` starts a local headless session. On a server, use the saved example data for offline stages.

## No course codes found

Check `PROGRAM_CODE`, `PROGRAM_ROUTE_TYPE`, and `ACADEMIC_YEAR`. Open the constructed URL in a browser and confirm that the year exists. A JavaScript-rendered page requires the Chrome stage, not a static request.

## HTTP failures

Check the console status and retry later. Keep the request delay enabled. Do not increase request volume to work around a temporary failure.

## Missing course fields

If many fields become empty, UQ may have changed its HTML identifiers. Save the page and report the URL, year, and affected field.

## Manual review rows

Free-text rules are expected. Review them in a spreadsheet and keep credit or grade rules as special requirements.

## Unknown course selector

Inspect available codes:

```r
igraph::V(g)$course_code
```

Course codes are case-sensitive in the configuration and selector calls.

## A figure is too dense

Reduce `depth`, choose fewer focus courses, or use a neighborhood rather than the full graph. Increase `width`, `height`, and `dpi` for a report figure.

## A prerequisite disappeared

Check whether `select_by_prefix()` removed it. Use `highlight_prefix` when cross-discipline context should remain.
