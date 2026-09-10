# Contributing

Bug reports, data-source breakage reports, documentation improvements, and pull requests are welcome. Please describe the UQ URL and year used, the expected behavior, the observed behavior, and the smallest reproducible example. Run the local R syntax checks and test suite before opening a pull request.

## Documentation changes

The published site is built from `docs-site/`. Use one Docsify theme, pin plugin versions, and load Mermaid before its Docsify plugin. Global navigation uses site-root Markdown paths; links within articles resolve relative to the current Markdown file (`relativePath: true`). Nested pages reuse the root sidebar and navbar through aliases in `index.html`.

Run `python scripts/check_docs.py` to check local links and images. Preview with `python -m http.server 8765 --directory docs-site`, then open `http://localhost:8765/` in a browser. The link check also runs before deployment; it does not replace browser checks.

Before publishing layout or navigation changes:

1. Reload the homepage and check that the graph is centered, the sidebar touches the viewport's left edge, and the page has no horizontal overflow.
2. Click the homepage workflow link, a nested selector page, a relative article link, and the previous/next links. Confirm the URL and article heading change together.
3. Click a chapter anchor in the sidebar and confirm the target heading scrolls into view after the scroll animation finishes.
4. Check image loading, image zoom, Mermaid diagrams, search results, and browser console errors.
5. Toggle the desktop menu. Repeat navigation at a narrow viewport (for example, 390 px); the menu should open at the left edge and close after selecting a page.
6. After the Pages workflow succeeds, reload the deployed site and repeat the key clicks. Test under `/uq-course-graph/`, since a root-only local preview cannot expose every subpath issue.
