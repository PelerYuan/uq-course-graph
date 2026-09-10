#' Build a directed course network
#'
#' Edges point from prerequisite to dependent course. Referenced codes outside the course table become explicit external nodes. Duplicate relationships are removed and invalid codes, fields, and self-edges are rejected. Both prerequisite and recommended-prerequisite relations are included.
#'
#' @param courses_file Path to a CSV course table. Graph building requires course_code and course_name; parsing also requires both prerequisite fields.
#' @param edges_file Path to a CSV containing course_code, prereq_code, and field.
#' @return A directed tidygraph tbl_graph.
#' @export
#' @examples
#' g <- build_course_graph(example_file("gallery_courses.csv"),
#'                         example_file("prereq_edges.csv"))
#' select_ancestors(g, "CSSE4010", depth = 1)
build_course_graph <- function(courses_file = "courses_info.csv", edges_file = "prereq_edges.csv") {
  courses <- .read_csv(courses_file)
  .validate_courses(courses)
  edges <- .read_csv(edges_file, c("course_code", "prereq_code", "field"))
  .course_codes(edges$course_code)
  .course_codes(edges$prereq_code)
  if (anyNA(edges$field) || any(!edges$field %in% .edge_fields)) stop("Unknown edge type.", call. = FALSE)
  if (any(edges$course_code == edges$prereq_code)) stop("Self-prerequisite edges are invalid.", call. = FALSE)
  edges <- unique(edges[, c("course_code", "prereq_code", "field"), drop = FALSE])
  nodes <- courses
  nodes$is_external <- FALSE
  external <- setdiff(unique(c(edges$course_code, edges$prereq_code)), nodes$course_code)
  if (length(external)) nodes <- dplyr::bind_rows(nodes, data.frame(course_code = external, is_external = TRUE))
  links <- data.frame(from = edges$prereq_code, to = edges$course_code, edge_type = edges$field)
  g <- tidygraph::tbl_graph(nodes = nodes, edges = links, directed = TRUE, node_key = "course_code")
  igraph::set_graph_attr(g, "provenance", list(package_version = .uq_version, built_at = .utc_now(),
    inputs = .fingerprints(c(courses_file, edges_file))))
}
#' Check for dependency cycles
#'
#' Returns FALSE and warns when a graph contains a cycle. The managed graph stage stops in this case.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @return A single logical value.
#' @export
check_dag <- function(g) {
  .validate_graph(g)
  result <- igraph::is_dag(g)
  if (!result) warning("The graph contains a cycle; inspect source and reviewed edges before plotting.", call. = FALSE)
  result
}
#' Rank courses by downstream reach
#'
#' Counts unique reachable downstream nodes using both relationship types. Ties are ordered by out-degree and course code. Reachability is not enrolment eligibility.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @return A sorted data frame with course_code, out_degree, in_degree, and downstream_count.
#' @export
rank_key_courses <- function(g) {
  .validate_graph(g)
  result <- data.frame(course_code = igraph::V(g)$course_code,
    out_degree = as.integer(igraph::degree(g, mode = "out")),
    in_degree = as.integer(igraph::degree(g, mode = "in")),
    downstream_count = vapply(seq_len(igraph::vcount(g)), function(i)
      length(igraph::subcomponent(g, i, mode = "out")) - 1L, integer(1)))
  result[order(-result$downstream_count, -result$out_degree, result$course_code), , drop = FALSE]
}
