# Pipeline overview

The numbered scripts are intentionally boring orchestration. They call reusable functions in `R/`, write predictable files, and can be rerun in order.

```mermaid
flowchart TB
 S[01_scrape.R] --> C[data/courses_info.csv]
 C --> P[02_parse.R]
 P --> R[data/prereq_edges.csv + logic + review]
 R --> M[03_review.R]
 M --> G[04_build_graph.R]
 G --> O[data/graph_object.rds]
 O --> V[05_visualize.R]
 V --> F[output/*.png]
```

Run from the repository root. Relative paths in the scripts are based on that directory.

| Stage | Network | Main input | Main output |
| --- | --- | --- | --- |
| Scrape | Yes | `config.R` | course CSV files |
| Parse | No | course CSV | edges, logic, review |
| Review | No | review CSV | corrected edges and special rules |
| Build | No | courses and edges | graph RDS and rankings |
| Visualize | No | graph RDS | PNG figures |

A stage should fail clearly when a required file is absent. Do not skip directly to visualization unless a graph object already exists.
