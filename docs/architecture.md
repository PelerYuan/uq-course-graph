# Architecture

The workflow has five executable stages. Scraping is the only network stage. Parsing, review, graph construction, and visualization consume files from `data/`, so they can be rerun offline.

Functions in `R/` are side-effect free when sourced; numbered scripts provide the user-facing orchestration.
