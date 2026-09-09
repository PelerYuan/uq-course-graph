# API reference

Source the module you need from `R/`. Sourcing a module only defines functions; it does not download data or create files.

## Scraping (`R/scrape.R`)

- `fetch_program_courses(url, output_file)` renders a plan or program page with Chrome and returns a `course_code` data frame. It stops when no rendered course codes are found.
- `extract_course_info(page)` extracts fields from one parsed course page.
- `fetch_course_details(course_codes, output_file, delay)` downloads course metadata, skips existing course codes, and records per-course failures.

## Parsing (`R/parse_prereq.R`)

- `is_clean_prereq(text)` checks whether text is a supported Boolean course expression.
- `tokenize_prereq(text)` tokenizes course codes, operators, commas, and parentheses.
- `parse_prereq_expr(tokens)` returns a nested `op`/`args` logic tree.
- `flatten_prereq_codes(node)` returns the unique course codes in a tree.
- `parse_all_prerequisites(courses_info, output_dir)` writes edges, logic trees, and manual-review rows.

## Manual review (`R/manual_review.R`)

- `generate_review_template(manual_review_file, output_file)` creates an editable CSV template.
- `review_manually(manual_review_file, output_file)` opens the optional desktop editor.
- `apply_manual_overrides(manual_review_file, template_file, edges_file, logic_file, special_file)` merges reviewed rows.

## Graph construction (`R/build_graph.R`)

- `build_course_graph(courses_file, edges_file)` returns a `tidygraph` object and adds external prerequisite nodes.
- `check_dag(g)` reports whether the graph contains cycles.
- `rank_key_courses(g)` returns downstream and degree rankings.

## Selection and plotting (`R/visualize_graph.R`)

- `tag_course_status(g, completed, current)` adds visual status labels.
- `select_courses(g, courses)` keeps only named nodes.
- `select_ancestors(g, courses, depth)` keeps upstream prerequisites.
- `select_descendants(g, courses, depth)` keeps downstream unlocks.
- `select_neighborhood(g, courses, depth)` keeps both directions.
- `select_by_prefix(g, prefixes)` hard-filters by the first four characters of a course code.
- `plot_course_graph(g, output_file, title, highlight_prefix, width, height, dpi)` renders and saves a graph.

## Statistics (`R/plot_stats.R`)

`plot_key_courses()`, `plot_prefix_by_level()`, `plot_prereq_count_by_level()`, `plot_class_hours()`, and `plot_assessment_mix()` each read CSV data and return a ggplot object after saving a PNG.
