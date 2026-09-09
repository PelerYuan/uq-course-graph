# Stage 4: build the graph

```r
source("04_build_graph.R")
```

The builder creates a `tidygraph` graph, adds external prerequisite nodes, checks for cycles, writes `data/graph_object.rds`, and ranks courses in `data/key_courses.csv`.

A valid prerequisite graph should normally be a DAG. A cycle means that the source rules or a manual correction should be inspected.
