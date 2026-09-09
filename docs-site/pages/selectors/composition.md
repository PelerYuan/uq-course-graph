# Combining selectors

Selectors return a graph, so they can be piped together.

```r
select_ancestors(g, "CSSE4010", depth = 3) |>
  select_by_prefix(c("CSSE", "MATH")) |>
  plot_course_graph("output/csse_math_chain.png",
                    title = "Filtered prerequisite chain")
```

The recommended order is:

1. choose the focus courses;
2. traverse ancestors, descendants, or a neighborhood;
3. apply a hard prefix filter only if removing other disciplines is intentional;
4. apply visual highlighting in `plot_course_graph()`;
5. save the result.

Use `highlight_prefix` instead of a hard filter when an outside discipline provides meaningful context.
