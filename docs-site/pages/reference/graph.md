# Graph reference

- `build_course_graph(courses_file, edges_file)` returns a `tidygraph` object and adds external nodes.
- `check_dag(g)` reports whether the graph is acyclic.
- `rank_key_courses(g)` returns direct degree and downstream reachability rankings.

The graph object is saved as an RDS file by `04_build_graph.R`.
