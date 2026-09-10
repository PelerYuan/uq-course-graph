# Migrating from the script prototype

Version 0.2.0 adds the installable `uqcoursegraph` package and changes the managed workflow's file layout and review contract. Keep a copy of your existing data and review decisions before adopting the new workflow.

## Configuration and paths

`config.R` is now ignored by Git. Your local file is retained when the repository stops tracking it. Compare it with `config.example.R` and add `REQUEST_RETRIES` if you want a non-default retry limit. All five numbered scripts now read the same configuration.

`DATA_DIR` and `OUTPUT_DIR` are roots, not the final source directory. Use `paths <- project_paths(load_config())`; graph data is at `paths$graph`. Old files directly under `data/` are not silently moved or reused.

```r
source("scripts/load_project.R")
config <- load_config()
import_course_data("data/courses_info.csv", config,
                   source_label = "My previous local UQ snapshot")
run_stage("parse", config)
run_stage("review", config)
```

The import validates required columns and refuses incomplete metadata. Do not invent missing fields simply to satisfy validation. Refresh the affected source when necessary.

## Review decisions

New templates require explicit pending, approved, or special status. The old convention of treating blank cleaned text as a finished special-rule decision is no longer accepted. Consult your old notes and re-enter decisions against the current raw text. Bare commas now require clarification; the old parser's assumption that every comma means OR is not preserved.

Templates already using stable review IDs retain their edits when re-generated. Changed source text receives a new ID and a pending decision; removed decisions are archived. Applying review twice no longer appends duplicate relationships.

## Functions and plotting

Use `library(uqcoursegraph)` after installation, or `source("scripts/load_project.R")` in a checkout. Directly sourcing a single module is no longer a supported loading method because functions share internal validators. Existing selector names and primary plotting arguments remain available.

Unknown exact course selections now fail instead of silently returning empty graphs. Prefix filters may return an empty graph; plotting it gives an explanatory error. Figure output includes a manifest sidecar. See the generated [function references](reference/workflow.md) for current signatures.
