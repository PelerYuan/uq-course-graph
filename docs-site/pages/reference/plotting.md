# Plotting reference

## `tag_course_status(g, completed, current)`

Adds status metadata used by the fill scale.

## `plot_course_graph(g, output_file, title, highlight_prefix, width, height, dpi)`

Renders a directed network graph and saves a PNG. `highlight_prefix` changes emphasis without removing nodes. The function returns the ggplot object invisibly so it can be further customized.
