# Stage 4: build the graph

```r
g <- run_stage("graph", config)
paths <- project_paths(config)
```

Graph building requires current parsing and completed review. It refuses changed templates or stale input tables. Canonical edges point from `prereq_code` to `course_code`. Duplicate relationships are removed; invalid codes, unsupported relationship fields, and self-prerequisites are rejected. The managed stage stops on cycles.

Referenced codes absent from the course table become external nodes. The saved graph contains source fingerprints; `key_courses.csv` records unique downstream reach. Neither the graph nor the ranking evaluates AND/OR enrolment conditions.

`paths$graph` points to the saved RDS. See the [graph reference](../reference/graph.md).
