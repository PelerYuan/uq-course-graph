# Contributing

Bug reports, data-source breakage reports, documentation improvements, and pull requests are welcome. Please describe the UQ URL and year used, the expected behavior, the observed behavior, and the smallest reproducible example. Run the checks below before opening a pull request. The package targets R >= 4.1; CI checks the current release on Linux and Windows. Public function documentation is generated from roxygen comments in `R/`.

## Package development

```sh
Rscript install_deps.R
Rscript -e 'install.packages(c("testthat", "roxygen2", "withr"))'
Rscript scripts/document.R
Rscript scripts/build_reference.R
Rscript -e 'testthat::test_local()'
Rscript scripts/verify_workflow.R
R CMD INSTALL .
Rscript scripts/verify_installed.R
R CMD build .
R CMD check uqcoursegraph_0.2.0.tar.gz --no-manual
```

Tests use small offline fixtures and mocked HTTP responses. Do not make the unit suite depend on live UQ availability. Add behavioral regressions for bugs, including failure and recovery paths. Keep personal configuration and generated workspaces out of Git. Record user-facing changes in `NEWS.md`; update DESCRIPTION and the internal version together when releasing. The source archive is the versioned release artifact; DESCRIPTION records dependency requirements and figure manifests record the actual runtime versions.

Edit roxygen comments, then regenerate both `man/` and the website reference. Do not edit generated reference pages independently. Commit those outputs with the implementation. The maintained tutorial has one home in `docs-site/`; avoid adding parallel guides under `docs/`.

## Documentation changes

The published site is built from `docs-site/`. Use one Docsify theme, pin plugin versions, and load Mermaid before its Docsify plugin. Global navigation uses site-root Markdown paths; links within articles resolve relative to the current Markdown file (`relativePath: true`). Nested pages reuse the root sidebar and navbar through aliases in `index.html`.

Run `python scripts/check_docs.py` to check local links and images. Preview with `node scripts/serve_docs.cjs`, then open `http://127.0.0.1:8766/uq-course-graph/` in a browser. Automated browser checks use this same subpath:

```sh
npm ci
npx playwright install chromium
npm run test:docs
```

Playwright checks desktop alignment, nested and relative navigation, gallery anchors/images/code, old malformed URLs, and the mobile menu. Failed runs retain a trace and HTML report. The link check also runs before deployment; it does not replace browser checks.

Before publishing layout or navigation changes:

1. Reload the homepage and check that the graph is centered, the sidebar touches the viewport's left edge, and the page has no horizontal overflow.
2. Click the homepage workflow link, a nested selector page, a relative article link, and the previous/next links. Confirm the URL and article heading change together.
3. Click a chapter anchor in the sidebar and confirm the target heading scrolls into view after the scroll animation finishes.
4. Check image loading, image zoom, Mermaid diagrams, search results, and browser console errors.
5. Toggle the desktop menu. Repeat navigation at a narrow viewport (for example, 390 px); the menu should open at the left edge and close after selecting a page.
6. After the Pages workflow succeeds, reload the deployed site and repeat the key clicks. Test under `/uq-course-graph/`, since a root-only local preview cannot expose every subpath issue.

### Gallery maintenance

Edit the recipes and explanations in `scripts/build_gallery.py`, which is the source of truth for both the downloadable R scripts and displayed code. From the repository root run:

```sh
python scripts/build_gallery.py
Rscript examples/gallery.R
python scripts/build_gallery.py --publish
python scripts/check_docs.py
```

The first command writes the individual recipes and Markdown. R executes those exact recipes against the bundled CSV snapshot. The publish command copies their actual PNG outputs into the site. Inspect the full network, a focused network, and statistics at normal and narrow browser widths before committing. Never substitute unrelated images when a recipe fails. Commit the generated scripts, page, images, and source changes together. Python uses only the standard library; R uses the existing project dependencies.
