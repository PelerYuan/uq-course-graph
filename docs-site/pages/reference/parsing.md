# Parsing reference

- `is_clean_prereq(text)` returns whether text is a supported course expression.
- `tokenize_prereq(text)` returns normalized tokens.
- `parse_prereq_expr(tokens)` returns a nested `op` and `args` tree.
- `flatten_prereq_codes(node)` returns course codes from a tree.
- `parse_all_prerequisites(courses_info, output_dir)` writes edge, logic, and review CSV files.

The parser supports nested AND and OR expressions. It deliberately sends mixed prose to manual review.
