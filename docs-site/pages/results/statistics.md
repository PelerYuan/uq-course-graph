# Statistics

The statistics functions read CSV outputs and answer questions about course distribution and workload.

![Gateway courses](../../assets/images/stat_key_courses.png)

![Discipline and level](../../assets/images/stat_prefix_by_level.png)

![Prerequisite load](../../assets/images/stat_prereq_by_level.png)

![Contact hours](../../assets/images/stat_class_hours.png)

![Assessment mix](../../assets/images/stat_assessment_mix.png)

Load the package, then use the same workspace as the pipeline:

```r
library(uqcoursegraph)
config <- uq_config()
paths <- project_paths(config)
plot_key_courses(file.path(paths$data, "key_courses.csv"),
  output_file = file.path(paths$output, "gateways.png"))
plot_prefix_by_level(paths$courses,
  output_file = file.path(paths$output, "disciplines.png"))
```

The images above are historical example outputs, not current catalogue statistics. The [gallery](../gallery.md) contains regenerated ranking and discipline examples with their complete code. Each new export includes an input-checksum and session sidecar.

The prerequisite-count chart counts listed graph relationships, including OR alternatives; recommended-prerequisite edges are excluded. It is not the number of courses a student must complete. Contact-hour charts include only supported weekly descriptions; assessment categories are keyword matches, overlap, and do not establish assessment weights. Missing data is not evidence of no workload. Consult the [plotting reference](../reference/plotting.md) for each function's inputs and behavior.
