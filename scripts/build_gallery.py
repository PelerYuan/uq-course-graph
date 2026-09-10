"""Build gallery recipes and documentation; use --publish after running R."""

import argparse
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
CASES = [
    ("01-overview", "The whole curriculum", "Where are the main pathways?",
     "The full graph provides context. Dense areas are a reason to switch to a focused selector; they are not a measure of course difficulty.",
     'view <- g', 'plot_course_graph(view, output_file, title = "Curriculum overview", width = 16, height = 10, dpi = 240)', "results/network.md"),
    ("02-exact", "A shortlist of courses", "How are these five courses connected?",
     "Only the named nodes and edges between them remain. Intermediate courses are not added automatically, so a missing edge does not prove two courses are unrelated.",
     'view <- select_courses(g, c("CSSE1001", "CSSE2010", "CSSE2310", "CSSE3010", "CSSE4010"))', None, "selectors/exact.md"),
    ("03-direct", "Direct prerequisites", "What immediately precedes CSSE4010?",
     "depth = 1 follows incoming edges by one step and retains the target. Compare this compact view with the next two examples.",
     'view <- select_ancestors(g, "CSSE4010", depth = 1)', None, "selectors/ancestors.md"),
    ("04-two-levels", "Two levels of prerequisites", "What comes before the direct prerequisites?",
     "depth = 2 adds one more upstream layer. The orange outline marks the queried course; other nodes provide prerequisite context.",
     'view <- select_ancestors(g, "CSSE4010", depth = 2)', None, "selectors/ancestors.md"),
    ("05-all-ancestors", "The complete prerequisite chain", "Which foundations lead to CSSE4010?",
     "depth = Inf retains every node reachable upstream. In this snapshot, depth = 1 keeps 5 nodes and depth = 2 already reaches all 7 upstream-and-focus nodes, so the two-level and unlimited views have the same nodes and edges. This is expected, not a selector failure. Traversal includes both prerequisite and recommended-prerequisite edges; inspect line styles and the parsed logic before making enrolment decisions.",
     'view <- select_ancestors(g, "CSSE4010", depth = Inf)', None, "selectors/ancestors.md"),
    ("06-descendants", "Downstream pathways", "Which courses are downstream of CSSE1001?",
     "The outgoing traversal shows structural reachability. Completing CSSE1001 alone does not make every displayed course available: other prerequisites, alternatives, grades, and offering rules still matter.",
     'view <- select_descendants(g, "CSSE1001", depth = Inf)', None, "selectors/descendants.md"),
    ("07-neighborhood", "A local neighborhood", "What is connected to CSSE2310 within one step?",
     "mode = all is used internally: incoming and outgoing edges are traversed without regard to direction. At larger depths this can include sibling branches, not just ancestors and descendants.",
     'view <- select_neighborhood(g, "CSSE2310", depth = 1)', None, "selectors/neighborhood.md"),
    ("08-prefix-filter", "Keep only one discipline", "What remains when only ELEC courses are kept?",
     "A hard filter removes all other prefixes, including any prerequisite bridges through mathematics or computing. Compare this with the next image, which preserves the full graph.",
     'view <- select_by_prefix(g, "ELEC")', None, "selectors/prefixes.md"),
    ("09-prefix-highlight", "Highlight without removing context", "Where does ELEC sit in the full curriculum?",
     "highlight_prefix dims other disciplines without deleting their nodes or edges. This image and the full overview contain the same network; only visual emphasis changes.",
     'view <- g', 'plot_course_graph(view, output_file, title = "ELEC in its curriculum context",\n                  highlight_prefix = "ELEC", width = 16, height = 10, dpi = 240)', "selectors/prefixes.md"),
    ("10-composition", "Combine traversal and discipline", "Which CSSE and ELEC courses are downstream of CSSE1001?",
     "First traverse the original graph, then keep two disciplines. Reversing this order can lose paths that pass through other prefixes. The final filtered graph can still omit those intermediate nodes.",
     'view <- select_descendants(g, "CSSE1001", depth = Inf) |>\n  select_by_prefix(c("CSSE", "ELEC"))', None, "selectors/composition.md"),
    ("11-gateways", "Gateway courses", "Which courses reach the largest downstream networks?",
     "The ranking is recomputed from the same example graph. Reachability counts are not degree requirements or a recommended study order; both edge types participate in this graph.",
     'ranking_file <- file.path(output_dir, "key_courses.csv")\nwrite.csv(rank_key_courses(g), ranking_file, row.names = FALSE)',
     'plot_key_courses(ranking_file, top_n = 12, output_file = output_file)', "results/statistics.md"),
    ("12-disciplines", "Discipline and course level", "How is the course list distributed?",
     "This chart counts the bundled course list rather than the graph, so external prerequisite nodes are excluded. Level is the fifth character of the course code, not a scheduled year of study.",
     '', 'plot_prefix_by_level(courses_file, output_file = output_file)', "results/statistics.md"),
]

SETUP = '''# Run from the repository root after installing dependencies.
source("scripts/load_project.R")

# A bundled example: no scraping, config.R, or private RDS file is needed.
courses_file <- "examples/gallery_courses.csv"
edges_file <- "examples/prereq_edges.csv"
g <- build_course_graph(courses_file, edges_file)

# Illustrative statuses, not a real student's record.
g <- tag_course_status(g,
  completed = c("CSSE1001", "MATH1051"), current = "CSSE2010")
output_dir <- "output/gallery"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20260910)
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--publish", action="store_true", help="Copy the generated PNGs into the site")
    mode.add_argument("--check", action="store_true", help="Check generated recipes and page without writing")
    args = parser.parse_args()
    recipes = ROOT / "examples/gallery"
    assets = ROOT / "docs-site/assets/images/gallery"
    if not args.check:
        recipes.mkdir(parents=True, exist_ok=True)
        assets.mkdir(parents=True, exist_ok=True)
    def save_or_check(path, text):
        if args.check:
            if not path.is_file() or path.read_text(encoding='utf-8') != text:
                raise SystemExit(f'Generated file is stale: {path.relative_to(ROOT)}')
        else:
            path.write_text(text, encoding='utf-8')
    page = ['''# Gallery

Choose a question, inspect the actual R output, and copy the complete code below it. Click any large result image to zoom, or open the original PNG to read individual labels. Every example can run independently from the repository root.

## Before you start

1. Follow [Installation](installation.md), clone the repository, and open R in the repository root.
2. Run `source("install_deps.R")` once if the dependencies are not installed.
3. Copy any complete code block below into R. Results are saved under `output/gallery/`.

To generate all 12 results in one run, use `source("examples/gallery.R")`, or run `Rscript examples/gallery.R` in a terminal. The [downloadable recipes](https://github.com/PelerYuan/uq-course-graph/tree/master/examples/gallery) contain the same code shown here.

These figures use a bundled ELECEX2350 example snapshot: `examples/gallery_courses.csv` (course codes and names) and `examples/prereq_edges.csv` (parsed relationships). They are examples, not a live course catalogue. Status colors are illustrative. No website requests or untracked `graph_object.rds` files are required.

**Read arrows from prerequisite to dependent course.** Solid edges represent prerequisites and dashed edges recommended prerequisites. An edge does not encode the complete AND/OR expression or credit and grade rules. See [limitations](results/limitations.md) before interpreting a path as an enrolment decision.

## Choose a view

<div class="gallery-grid">
''']
    # Put the visual index before setup details so visitors see results first.
    intro, remainder = page.pop().split('## Before you start', 1)
    setup_details, visual_index = remainder.split('## Choose a view', 1)
    page.append(intro + '## Choose a view' + visual_index)
    for slug, title, question, note, selection, plot, tutorial in CASES:
        page.append(f'<a class="gallery-card" href="#/pages/gallery?id=view-{slug}"><img src="assets/images/gallery/{slug}.png" alt="{title}" loading="lazy"><strong>{title}</strong><span>{question}</span></a>\n')
    page.append('</div>\n')
    page.append('## Before you start' + setup_details)
    for slug, title, question, note, selection, plot, tutorial in CASES:
        plot = plot or f'plot_course_graph(view, output_file, title = "{title}",\n                  width = 12, height = 8, dpi = 240)'
        code = SETUP + f'output_file <- file.path(output_dir, "{slug}.png")\n\n' + (selection + '\n' if selection else '') + plot + '\n'
        save_or_check(recipes / f'{slug}.R', code)
        image = f'../assets/images/gallery/{slug}.png'
        page.append(f'''\n## {title} :id=view-{slug}

**{question}** {note}

![{title}: {question}]({image})

[Open original PNG]({image} ':ignore') | [Read the tutorial]({tutorial}) | [Download this R recipe](https://raw.githubusercontent.com/PelerYuan/uq-course-graph/master/examples/gallery/{slug}.R ':ignore')

```r
{code}```
''')
        if args.publish:
            source = ROOT / 'output/gallery' / f'{slug}.png'
            if not source.is_file():
                raise SystemExit(f'Missing {source}; run Rscript examples/gallery.R first.')
            shutil.copyfile(source, assets / source.name)
    page.append('''
## Use your own curriculum

After the [complete workflow](getting-started.md) has built your graph, replace the `build_course_graph(...)` line in a network recipe with the following setup:

```r
config <- load_config()
paths <- project_paths(config)
g <- readRDS(paths$graph)
courses_file <- paths$courses
```

 Choose course codes and prefixes that exist in your graph, and update the illustrative status lists. Each exported figure receives a `.manifest.json` sidecar with input checksums, plot settings, and session information.

`depth = 1`, `depth = 2`, and `depth = Inf` change how far a traversal reaches. `select_by_prefix()` removes nodes; `highlight_prefix` changes their appearance. `width` and `height` are in inches; together with `dpi` they determine the PNG resolution. The examples deliberately use different plot sizes for the full network and focused views.

Find signatures in the [selector reference](reference/selectors.md) and [plotting reference](reference/plotting.md). Continue with [selector recipes](selectors/overview.md) for more explanation, or [troubleshooting](troubleshooting.md) if a code is missing or your result differs. Exact label positions can vary with R packages, fonts, and graphics devices even with a fixed seed.
''')
    save_or_check(ROOT / 'docs-site/pages/gallery.md', '\n'.join(page))
    print(f'{"Checked" if args.check else "Built"} {len(CASES)} complete recipes and the gallery page.')


if __name__ == '__main__':
    main()
