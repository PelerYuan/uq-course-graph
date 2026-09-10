# Reproducibility

The managed workflow writes `run_manifest.json` and `sessionInfo.txt` in each source-specific data directory. The manifest records the configuration, package version, requirements URL, stage times, and SHA-256 fingerprints of each stage's inputs and outputs.

The plot stage also copies the completed run manifest to the figure directory. Individual images receive an adjacent `.manifest.json`: network figures record the graph's original input fingerprints, selected course statuses, image checksum, dimensions, and seed; statistical figures record their CSV input hashes and software session.

## Keep source identities separate

`project_paths(config)` adds a route-code-year subdirectory. Two years or curricula do not reuse the same managed cache. Successful scrape rows include source URL, requested year, and retrieval timestamp. Offline imports record their source label, checksum, and import time. An unknown original retrieval date stays unknown; importing a file does not make its contents current.

## Understand freshness errors

When an upstream file changes, a later stage stops rather than silently using stale results. Re-import or refresh a changed source, then rerun parse, review, graph, and plot in order. A changed review template needs review applied again before graph construction.

Do not edit generated automatic tables in place to bypass the review process. Put decisions in the template. Direct lower-level function calls are available, but they do not perform the managed pipeline's stage freshness checks.

## Preserve a reproducible result

Keep the relevant CSV inputs, review decisions, figure sidecars, run manifest, and source version together. Pin the repository commit or release when sharing a result. Package versions and fonts can affect layout even with the same seed. Manifests describe what was used; they do not archive every input or install an identical software environment automatically.

The bundled gallery snapshot has no recorded retrieval date. Its code and images are reproducible examples, not a current UQ catalogue. See [migration](migration.md) when bringing an older local project into version 0.2.0.
