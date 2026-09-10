# Review reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `generate_review_template()`

Preserves status, cleaned_text, and note when source text is unchanged. New or changed expressions are pending. Removed entries are archived beside the template.

```r
generate_review_template (manual_review_file = "manual_review.csv", output_file = "manual_review_template.csv")
```

| Argument | Meaning |
| --- | --- |
| `manual_review_file` | Current parser review CSV containing source course, field, raw text, and reason. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** The current review data frame, also saved as CSV.

## `apply_manual_overrides()`

Requires every row to be approved or special. Approved rows require a valid cleaned expression; special rows require a note. Source columns must remain unchanged. Replaces affected relationships from automatic base tables, so repeated calls do not duplicate edges. All decisions are validated before result files are written.

```r
apply_manual_overrides (template_file = "manual_review_template.csv", edges_file = "prereq_edges.csv",
    logic_file = "prereq_logic.csv", special_file = "special_requirements.csv",
    manual_review_file = file.path(dirname(template_file), "manual_review.csv"))
```

| Argument | Meaning |
| --- | --- |
| `template_file` | Review template with stable review_id and status columns. |
| `edges_file` | Path to a CSV containing course_code, prereq_code, and field. |
| `logic_file` | Path to a CSV containing course_code, field, raw_text, and logic_tree. |
| `special_file` | Output CSV for explicitly reviewed non-course requirements. |
| `manual_review_file` | Current parser review CSV containing source course, field, raw text, and reason. |

**Returns:** A list containing edges, logic, and special_requirements data frames.

## `review_manually()`

Optional desktop editor. For headless use, generate a template and edit its CSV in a spreadsheet.

```r
review_manually (manual_review_file = "manual_review.csv", output_file = "manual_review_template.csv")
```

| Argument | Meaning |
| --- | --- |
| `manual_review_file` | Current parser review CSV containing source course, field, raw text, and reason. |
| `output_file` | Output file path. Parent directories are created when needed. |

**Returns:** The edited data frame.
