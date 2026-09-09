# Statistics

The statistics functions read CSV outputs and answer questions about course distribution and workload.

![Gateway courses](../../assets/images/stat_key_courses.png)

![Discipline and level](../../assets/images/stat_prefix_by_level.png)

![Prerequisite load](../../assets/images/stat_prereq_by_level.png)

![Contact hours](../../assets/images/stat_class_hours.png)

![Assessment mix](../../assets/images/stat_assessment_mix.png)

Run the functions from `R/plot_stats.R` and keep the input CSV files with exported images. The prerequisite-count plot treats OR alternatives as separate listed courses, so its values are an upper bound.
