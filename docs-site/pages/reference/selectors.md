# Selectors reference

Generated from the package's R help files. These signatures, parameters, and return values are checked against the source. See the [gallery](../gallery.md) for complete visual examples or the [workflow](../getting-started.md) for a guided run.

For an installed package, use `library(uqcoursegraph)` and `?function_name`. In a clone, run `source("scripts/load_project.R")` first.

## `select_courses()`

Keeps only the supplied nodes and edges between them. Unknown or malformed codes raise an error.

```r
select_courses (g, courses)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `courses` | Character vector of course codes present in the graph, such as "CSSE1001". |

**Returns:** A graph with focus markers.

## `select_ancestors()`

Traverses incoming edges of both relationship types. A flattened path does not evaluate AND/OR requirements.

```r
select_ancestors (g, courses, depth = Inf)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `courses` | Character vector of course codes present in the graph, such as "CSSE1001". |
| `depth` | Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses. |

**Returns:** A graph containing the focus courses and reachable upstream nodes.

## `select_descendants()`

Traverses outgoing edges of both relationship types. Displayed courses may have additional requirements.

```r
select_descendants (g, courses, depth = Inf)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `courses` | Character vector of course codes present in the graph, such as "CSSE1001". |
| `depth` | Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses. |

**Returns:** A graph containing focus courses and reachable downstream nodes.

## `select_neighborhood()`

Traverses edges in either direction. At greater depths, sibling branches can be included.

```r
select_neighborhood (g, courses, depth = 2)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `courses` | Character vector of course codes present in the graph, such as "CSSE1001". |
| `depth` | Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses. |

**Returns:** A graph containing nodes within the requested undirected distance.

## `select_by_prefix()`

Removes nonmatching nodes, potentially removing intermediate paths. Use plot highlighting to retain context.

```r
select_by_prefix (g, prefixes)
```

| Argument | Meaning |
| --- | --- |
| `g` | A directed igraph or tidygraph course graph with unique course_code attributes. |
| `prefixes` | One or more four-letter uppercase discipline prefixes. |

**Returns:** A graph, which may be empty if no prefix matches.
