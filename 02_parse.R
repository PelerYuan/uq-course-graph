source("scripts/load_project.R")
config <- load_config(Sys.getenv("UQCOURSEGRAPH_CONFIG", "config.R"))
run_stage("parse", config)
