# Workflow reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `uq_config()`

All managed stages use the same settings. Data and outputs are separated by route, code, and requested year.

```r
uq_config (program_code = "ELECEX2350", academic_year = 2026,
    route_type = "plan", data_dir = "data", output_dir = "output",
    completed = character(), current = character(), delay = 1,
    timeout = 30, retries = 2, user_agent = "uqcoursegraph/0.2.0")
```

| Argument | Meaning |
| --- | --- |
| `program_code` | Alphanumeric program or plan code from a UQ requirements URL. |
| `academic_year` | Integer requested catalogue year. In fetch_course_details(), NULL requests the current page. |
| `route_type` | Either "plan" or "program". |
| `data_dir` | Base data directory. A route-code-year subdirectory is added automatically. |
| `output_dir` | Directory for generated files, or the base output directory in configuration. |
| `completed` | Character vector of course codes to mark completed. Must not overlap current. |
| `current` | Character vector of course codes to mark in progress. |
| `delay` | Non-negative delay in seconds between requests. Retries use exponential backoff. |
| `timeout` | Positive request timeout in seconds. |
| `retries` | Non-negative integer number of retries after the initial attempt. |
| `user_agent` | Non-empty User-Agent string sent with requests. |

**Returns:** A uq_config list.

## `load_config()`

Maps uppercase settings from config.R to uq_config(). Missing required source settings and invalid values cause errors.

```r
load_config (path = "config.R")
```

| Argument | Meaning |
| --- | --- |
| `path` | Path to a local R configuration file. Only source a configuration file you trust. |

**Returns:** A validated uq_config list.

## `project_paths()`

Computes paths without creating files. Each source uses its own route-code-year subdirectory.

```r
project_paths (config)
```

| Argument | Meaning |
| --- | --- |
| `config` | Validated configuration returned by uq_config() or load_config(). |

**Returns:** A named list of absolute input, output, review, graph, and manifest paths.

## `example_file()`

Provides offline input files in an installed package or a source checkout. See the bundled README for provenance and limitations.

```r
example_file (name = "courses.csv")
```

| Argument | Meaning |
| --- | --- |
| `name` | Name of a bundled example CSV: courses.csv, gallery_courses.csv, prereq_edges.csv, or demo_courses.csv (synthetic). |

**Returns:** A file path.

## `import_course_data()`

Validates a supplied table and records its checksum and source label. The import timestamp is not treated as its original retrieval date.

```r
import_course_data (courses_file, config = uq_config(), overwrite = FALSE,
    source_label = "User-supplied offline snapshot")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `config` | Validated configuration returned by uq_config() or load_config(). |
| `overwrite` | Logical; explicitly allow replacing an existing imported snapshot. |
| `source_label` | Description of the offline data source, recorded in the manifest. |

**Returns:** Workspace paths invisibly.

## `run_stage()`

Uses one configuration and records file checksums in run_manifest.json. Review pauses when decisions are pending. Graph and plot refuse stale prerequisites. Figures receive a manifest sidecar and the data directory records sessionInfo().

```r
run_stage (stage, config = uq_config(), refresh = FALSE)
```

| Argument | Meaning |
| --- | --- |
| `stage` | One of scrape, parse, review, graph, or plot. |
| `config` | Validated configuration returned by uq_config() or load_config(). |
| `refresh` | Logical; TRUE downloads successful cached records again. |

**Returns:** Stage-specific data invisibly: a data frame, result list, graph, or plot. Pending review returns status and template path.

## `run_pipeline()`

The default runs offline stages after import. Stops at pending review; resume with review, graph, and plot after editing. Include scrape explicitly for network collection.

```r
run_pipeline (config = uq_config(), stages = c("parse", "review",
    "graph", "plot"))
```

| Argument | Meaning |
| --- | --- |
| `config` | Validated configuration returned by uq_config() or load_config(). |
| `stages` | Unique stage names in pipeline order. The default excludes network collection. |

**Returns:** Workspace paths invisibly after successful completion.
