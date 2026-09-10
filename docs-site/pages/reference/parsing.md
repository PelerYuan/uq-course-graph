# Parsing reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `is_clean_prereq()`

Checks lexical support only. A TRUE result does not guarantee valid grammar; use tokenize_prereq() and parse_prereq_expr() to validate a complete expression.

```r
is_clean_prereq (text)
```

| Argument | Meaning |
| --- | --- |
| `text` | One non-missing prerequisite expression string. Only explicit course codes, AND, OR, and parentheses are parsed automatically. |

**Returns:** A single logical value.

## `tokenize_prereq()`

Rejects free text and ambiguous bare commas. Explicit comma-and or comma-or conjunctions are accepted, as is one trailing period or semicolon.

```r
tokenize_prereq (text)
```

| Argument | Meaning |
| --- | --- |
| `text` | One non-missing prerequisite expression string. Only explicit course codes, AND, OR, and parentheses are parsed automatically. |

**Returns:** A character vector of course codes, operators, and parentheses.

## `parse_prereq_expr()`

Uses AND precedence over OR and supports nested parentheses. Rejects missing operands, unbalanced parentheses, unsupported tokens, and trailing tokens.

```r
parse_prereq_expr (tokens)
```

| Argument | Meaning |
| --- | --- |
| `tokens` | Character vector returned by tokenize_prereq(). |

**Returns:** A course-code string or nested list with op and args. Errors never return partial trees.

## `flatten_prereq_codes()`

Returns the unique course-code leaves without preserving the distinction between alternatives and joint requirements.

```r
flatten_prereq_codes (node)
```

| Argument | Meaning |
| --- | --- |
| `node` | A course-code leaf or a validated nested AND/OR logic tree. |

**Returns:** A character vector of course codes.

## `parse_all_prerequisites()`

Unsupported or malformed expressions go to manual review. Writes automatic base tables, canonical edge and logic tables, and a review queue. Re-parsing resets canonical tables; rerun review before building a graph. Empty outputs retain column headers.

```r
parse_all_prerequisites (courses_info, output_dir = ".")
```

| Argument | Meaning |
| --- | --- |
| `courses_info` | Data frame containing unique course_code, course_name, prerequisite, and recommended_prerequisite columns. |
| `output_dir` | Directory for generated files, or the base output directory in configuration. |

**Returns:** A list containing edges, logic, and manual_review data frames.
