# Graph reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `build_course_graph()`

Edges point from prerequisite to dependent course. Referenced codes outside the course table become explicit external nodes. Duplicate relationships are removed and invalid codes, fields, and self-edges are rejected. Both prerequisite and recommended-prerequisite relations are included.

```r
build_course_graph (courses_file = "courses_info.csv", edges_file = "prereq_edges.csv")
```

| Argument | Meaning |
| --- | --- |
| `courses_file` | Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields. |
| `edges_file` | Path to a CSV containing course_code, prereq_code, and field. |

**Returns:** A directed tidygraph tbl_graph.

## `check_dag()`

Returns FALSE and warns when a graph contains a cycle. The managed graph stage stops in this case.

```r
check_dag (g)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |

**Returns:** A single logical value.

## `rank_key_courses()`

Counts unique reachable downstream nodes using both relationship types. Ties are ordered by out-degree and course code. Reachability is not enrolment eligibility.

```r
rank_key_courses (g)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |

**Returns:** A sorted data frame with course_code, out_degree, in_degree, and downstream_count.
