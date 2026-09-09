# Prerequisite chains

`select_ancestors()` follows incoming prerequisite edges.

```r
select_ancestors(g, "CSSE4010", depth = 1) |>
  plot_course_graph("output/csse4010_depth1.png", title = "Direct prerequisites")

select_ancestors(g, "CSSE4010", depth = 2) |>
  plot_course_graph("output/csse4010_depth2.png", title = "Two levels of prerequisites")
```

![Two-level prerequisite chain](../../assets/images/subgraph_csse4010_prereqs.png)

Use a small depth for a readable plan. Use `Inf` when you need every reachable foundation course.
