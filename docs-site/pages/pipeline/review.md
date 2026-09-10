# Stage 3: review ambiguous rules

The review stage is an explicit checkpoint. It never silently treats unfinished rows as non-course rules and never automatically approves a rewritten expression.

```r
run_stage("review", config)
paths <- project_paths(config)
paths$template
```

## Fill the template

Each row contains immutable `review_id`, `course_code`, `field`, `raw_text`, and `reason` columns. The ID is derived from the source text and identifies the decision you are making. Edit only these three columns:

- `status`: `pending`, `approved`, or `special`.
- `cleaned_text`: an explicit course expression for an approved decision.
- `note`: your reasoning; required for a special rule.

For an ambiguous source such as `CSSE1001, MATH1051`, first inspect the official page or obtain clarification. Only then replace the comma with the verified `and` or `or`. The parser deliberately does not guess this meaning.

For a source such as `32 units completed`, use `special` and a note such as `Unit threshold requires separate verification`. Keep a mixed rule as special when simplifying it would conceal a condition. The original text and note remain available in the special requirements CSV.

## Apply and verify

```r
run_stage("review", config)
read.csv(paths$special)
run_stage("graph", config)
```

If a row is pending, review returns a pending result and graph building remains blocked. Invalid approved expressions fail before result files are replaced. The new canonical tables are rebuilt from automatic base tables and current decisions. Reapplying the same template is idempotent.

## When the source changes

Re-import or refresh the source, run parse, then review. Unchanged expressions keep their decisions. Changed or removed expressions are preserved in `manual_review_template_archive.csv`; changed expressions require a new decision. Do not copy an old approval onto different source text without reviewing it.

The [review reference](../reference/review.md) also documents the lower-level template and override functions. The optional interactive editor is for desktop R; spreadsheet CSV review works without a GUI.
