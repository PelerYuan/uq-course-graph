# Unlocked courses

`select_descendants()` follows outgoing edges from a course.

```r
select_descendants(g, "CSSE1001", depth = Inf) |>
  plot_course_graph("output/csse1001_unlocks.png",
                    title = "Courses unlocked by CSSE1001")
```

![Unlocked courses](../../assets/images/subgraph_csse1001_unlocks.png)

This view answers “what does completing this foundation make available?” It does not mean that every descendant is immediately enrollable: other prerequisites, offerings, and degree rules may still apply.
