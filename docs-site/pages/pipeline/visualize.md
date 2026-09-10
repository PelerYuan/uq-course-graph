# Stage 5: create visualizations

```r
run_stage("plot", config)
paths <- project_paths(config)
```

The managed plot stage verifies graph freshness, applies the configured course status colors, and saves a PNG and a run manifest in `paths$output`. The figure's adjacent `.manifest.json` records graph input fingerprints, selection, size, seed, and software session. Individual selector plots also write figure sidecars.

For a focused graph, load `g <- readRDS(paths$graph)` and use the [gallery](../gallery.md) or [selector guide](../selectors/overview.md). `width` and `height` are inches; `dpi` sets raster resolution. `seed` controls label placement without changing the caller's random-number state. Empty selections fail with a descriptive message.

The statistical plots read CSV inputs and write their own image manifests. See the [plotting reference](../reference/plotting.md) and [statistics guide](../results/statistics.md).
