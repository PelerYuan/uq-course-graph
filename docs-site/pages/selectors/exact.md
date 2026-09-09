# Exact course selection

`select_courses()` keeps only the requested nodes and edges between them.

```r
select_courses(g, c("CSSE2002", "CSSE2310")) |>
  plot_course_graph("output/exact_courses.png", title = "Selected courses")
```

Use it for a small presentation or to check whether two courses have a direct relationship. It does not add prerequisites or descendants. If you want context around the courses, use `select_neighborhood()` instead.
