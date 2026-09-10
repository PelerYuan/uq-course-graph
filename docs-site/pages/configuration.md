# Configuration

`uq_config()` validates settings before any managed stage runs. The [workflow API reference](reference/workflow.md) lists every argument and its default.

```r
config <- uq_config(
  program_code = "ELECEX2350", academic_year = 2026, route_type = "plan",
  data_dir = "data", output_dir = "output",
  completed = character(), current = character(),
  delay = 1, timeout = 30, retries = 2,
  user_agent = "uqcoursegraph/0.2.0"
)
paths <- project_paths(config)
```

`paths$data` is `data/plan-ELECEX2350-2026` under the current working directory. Changing code, route, or year selects a different directory. `paths$output` uses the same source ID under the output root. Use these returned paths rather than hardcoding `data/graph_object.rds`.

## Local settings for numbered scripts

Copy `config.example.R` to `config.R` without overwriting an existing file, then edit the local file. `config.R` is ignored by Git. `load_config()` reads it; `UQCOURSEGRAPH_CONFIG` can point the numbered scripts to a different file.

| R API argument | Local configuration name | Meaning |
| --- | --- | --- |
| `program_code` | `PROGRAM_CODE` | Code from the requirements URL |
| `academic_year` | `ACADEMIC_YEAR` | Requested catalogue year |
| `route_type` | `PROGRAM_ROUTE_TYPE` | `plan` or `program` |
| `data_dir` | `DATA_DIR` | Root containing source-specific data directories |
| `output_dir` | `OUTPUT_DIR` | Root containing source-specific figure directories |
| `completed` | `COMPLETED_COURSES` | Illustrative completed-course status |
| `current` | `CURRENT_COURSES` | In-progress status; cannot overlap completed |
| `delay` | `REQUEST_DELAY` | Pause between requests in seconds |
| `timeout` | `REQUEST_TIMEOUT` | Request and page-wait timeout in seconds |
| `retries` | `REQUEST_RETRIES` | Additional attempts after the first failure |
| `user_agent` | `USER_AGENT` | Request identification string |

Only load R configuration files you trust: an R configuration file is executable code. To avoid sourcing files, construct `uq_config()` directly. Keep personal progress choices in your local configuration; they also appear in locally generated figure manifests when used for plotting.
