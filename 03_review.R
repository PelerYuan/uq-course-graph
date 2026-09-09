source("R/manual_review.R")
generate_review_template("data/manual_review.csv", "data/manual_review_template.csv")
cat("Edit data/manual_review_template.csv, then run 03_review.R again.\n")
