# Source checkout functions without installing the package.
# Keep this file outside R/ so installed namespaces never source local files.
if (!file.exists("DESCRIPTION") || !dir.exists("R")) stop("Run from the repository root.")
for (.uq_file in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  sys.source(.uq_file, envir = .GlobalEnv)
}
rm(.uq_file)
