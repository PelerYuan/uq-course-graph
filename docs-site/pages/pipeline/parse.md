# Stage 2: parse prerequisites

```r
source("02_parse.R")
```

The parser recognizes nested expressions such as:

```text
ENGG1300 and (MATH1051 or MATH1071)
```

It writes:

- `data/prereq_edges.csv` for graph traversal;
- `data/prereq_logic.csv` for preserved Boolean structure;
- `data/manual_review.csv` for unsupported or ambiguous text.

OR alternatives are flattened into multiple edges for traversal. The logic JSON remains the authoritative representation when you need to distinguish alternatives from mandatory combinations.
