# Examples

This directory contains a captured ELECEX2350 example dataset and figures. It allows the parsing, graph, and visualization stages to be explored without making network requests.

## Reproduce the gallery

Run `source("install_deps.R")` once, then `source("examples/gallery.R")` from the repository root. Each script in `examples/gallery/` is also independently runnable and includes its own setup. PNGs and the computed gateway ranking are written to `output/gallery/`.

The gallery uses `gallery_courses.csv`, a projection of the locally captured course metadata containing only `course_code` and `course_name`, together with the existing `prereq_edges.csv`. The full snapshot capture date has not been recorded; these tables must not be treated as a current UQ catalogue. They contain no student progress data. Course status colors are assigned explicitly in each recipe for illustration.

The graph builder adds referenced courses absent from the course list as external nodes. Network selectors traverse both edge types. The discipline chart counts only the supplied course list. Refer to the gallery explanations for the interpretation of each figure.
