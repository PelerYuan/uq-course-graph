# Selector overview

Start with the [gallery](../gallery.md) to compare actual outputs and copy a complete runnable example, then use this guide to understand the selectors.

Selectors answer planning questions by returning a graph containing only relevant nodes. They do not edit the original graph.

```r
source("R/visualize_graph.R")
g <- readRDS("data/graph_object.rds")
g <- tag_course_status(g, COMPLETED_COURSES, CURRENT_COURSES)
```

| Question | Function |
| --- | --- |
| Show these exact courses | `select_courses()` |
| What must come first? | `select_ancestors()` |
| What can this unlock? | `select_descendants()` |
| What is nearby in either direction? | `select_neighborhood()` |
| Keep only disciplines | `select_by_prefix()` |
| Emphasize disciplines but keep context | `highlight_prefix` |

Every traversal selector accepts one course code or a vector of codes. `depth = 1` means one edge; `depth = Inf` follows all reachable nodes.

Start with [exact selection](exact.md), then continue through [prerequisites](ancestors.md), [unlocks](descendants.md), and [composition](composition.md).
