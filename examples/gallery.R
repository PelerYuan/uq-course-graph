# Generate every gallery figure from the bundled public example tables.
# Run from the repository root: Rscript examples/gallery.R
if (!file.exists("examples/gallery_courses.csv")) {
  stop("Run this script from the repository root.")
}
recipes <- sort(list.files("examples/gallery", pattern = "\\.R$", full.names = TRUE))
if (length(recipes) != 12L) stop("Expected 12 gallery recipes.")
for (recipe in recipes) {
  message("Running ", recipe)
  source(recipe, local = new.env(parent = globalenv()))
}
message("All gallery figures saved in output/gallery/.")
