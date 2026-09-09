source("R/parse_prereq.R")
courses <- read.csv(file.path("data", "courses_info.csv"), stringsAsFactors = FALSE)
parse_all_prerequisites(courses, "data")
