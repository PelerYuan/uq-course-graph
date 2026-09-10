# Troubleshooting

## No rendered course codes

Check the requirements URL in a browser, including its route and year. Verify Chrome and `chromote` installation. Increase the configured timeout if the page is slow. UQ markup can change; do not treat an empty scrape as a valid curriculum.

## Failed downloads remain

Inspect `fetch_status` and `error` in `courses_info.csv`, then rerun scrape. Successful rows from the same source resume; failures retry. Use `refresh = TRUE` to deliberately refresh successful records. Fix connectivity, server errors, or changed HTML rather than removing the failure status manually.

## Pipeline paused for manual review

Open the printed template path. Set every inspected row to approved with a valid cleaned expression, or special with a note. Keep source columns unchanged. Save and rerun review, graph, and plot. See the [review walkthrough](pipeline/review.md).

## Stale result or template

An input or decision changed after its downstream result was generated. For a changed source, re-import or scrape, then parse again. For a changed template, rerun review. Then rebuild and plot. Changed source expressions need fresh decisions even if an old template contains an approval.

## Missing columns

Check that you supplied the right CSV. Parsing needs both prerequisite fields and course names. The gallery's minimal course-name table supports graph examples but not the parser, assessment, or contact-hours plots. The [complete workflow](getting-started.md) uses a separate synthetic metadata file for its offline tutorial.

## Missing or empty selection

Use a code present in `igraph::V(g)$course_code`. Course codes are uppercase four-letter/four-digit identifiers. A prefix filter removes unmatched nodes and may break paths. Increase depth or use highlighting if you want to retain context.

## Invalid old documentation URL

Older site versions could turn a page route into an `id` query parameter. The current site redirects those known malformed routes to their proper pages. Reload the site if an old tab still uses cached scripts. Report the exact URL if a link still fails.
