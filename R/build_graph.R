library(tidygraph)
library(igraph)
library(dplyr)


#'
#'
#'
build_course_graph <- function(courses_file = "courses_info.csv",
                                edges_file = "prereq_edges.csv") {

  courses <- read.csv(courses_file, stringsAsFactors = FALSE)
  edges_raw <- read.csv(edges_file, stringsAsFactors = FALSE)

  nodes <- courses %>% distinct(course_code, .keep_all = TRUE)

  known_codes <- nodes$course_code
  referenced_codes <- unique(c(edges_raw$course_code, edges_raw$prereq_code))
  external_codes <- setdiff(referenced_codes, known_codes)

  if (length(external_codes) > 0) {
    cat(sprintf("Found %d external course codes not in course list, adding as bare nodes\n",
                length(external_codes)))
    nodes <- bind_rows(nodes, tibble(course_code = external_codes))
  }

  edges <- edges_raw %>%
    transmute(from = prereq_code, to = course_code, edge_type = field)

  tbl_graph(nodes = nodes, edges = edges, directed = TRUE, node_key = "course_code")
}


#'
#'
check_dag <- function(g) {
  is_dag <- igraph::is_dag(g)
  cat(sprintf("Is DAG: %s\n", is_dag))

  if (!is_dag) {
    scc <- igraph::components(g, mode = "strong")
    cyclic_ids <- which(scc$csize[scc$membership] > 1)
    cyclic_codes <- igraph::V(g)$course_code[cyclic_ids]
    cat("Cycle detected, involved courses:\n")
    print(unique(cyclic_codes))
  }

  is_dag
}


#'
#'
rank_key_courses <- function(g) {
  codes <- igraph::V(g)$course_code

  out_deg <- igraph::degree(g, mode = "out")
  in_deg <- igraph::degree(g, mode = "in")

  downstream_count <- sapply(seq_along(codes), function(i) {
    length(igraph::subcomponent(g, i, mode = "out")) - 1
  })

  tibble(
    course_code = codes,
    out_degree = out_deg,
    in_degree = in_deg,
    downstream_count = downstream_count
  ) %>%
    arrange(desc(downstream_count), desc(out_degree))
}



