# Selector reference

## `select_courses(g, courses)`

Keeps only named nodes and edges between them.

## `select_ancestors(g, courses, depth = Inf)`

Keeps focus courses and upstream prerequisites. `depth = 1` means direct prerequisites.

## `select_descendants(g, courses, depth = Inf)`

Keeps focus courses and downstream courses that depend on them.

## `select_neighborhood(g, courses, depth = 2)`

Keeps nodes in both directions within the requested depth.

## `select_by_prefix(g, prefixes)`

Hard-filters nodes by the first four characters of `course_code`.

All selector functions return a graph and leave the input object unchanged. Unknown course codes produce an error so a misspelled focus course cannot silently create an empty figure.
