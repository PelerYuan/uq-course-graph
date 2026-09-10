.validate_graph <- function(g) {
  if (!inherits(g, "igraph") || !igraph::is_directed(g) ||
      !"course_code" %in% igraph::vertex_attr_names(g))
    stop("g must be a directed course graph with course_code attributes.", call. = FALSE)
  .course_codes(igraph::V(g)$course_code)
  if (anyDuplicated(igraph::V(g)$course_code)) stop("Duplicate graph course codes.", call. = FALSE)
  invisible(g)
}

#' Tag illustrative course progress
#'
#' Adds presentation status without changing relationships. Missing course names identify legacy external nodes. Completed and current sets cannot overlap.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param completed Character vector of course codes to mark completed. Must not overlap current.
#' @param current Character vector of course codes to mark in progress.
#' @return A graph with status attributes.
#' @export
tag_course_status <- function(g, completed = character(), current = character()) {
  g <- tidygraph::as_tbl_graph(g)
  .validate_graph(g)
  .course_codes(completed)
  .course_codes(current)
  if (length(intersect(completed, current))) stop("Completed and current courses must not overlap.", call. = FALSE)
  g |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(status = dplyr::case_when(
      course_code %in% completed ~ "completed",
      course_code %in% current   ~ "current",
      is.na(course_name)         ~ "external",
      TRUE                       ~ "future"
    ))
}

build_subgraph <- function(g, keep_codes, focus_codes) {
  g <- tidygraph::as_tbl_graph(g)
  g |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(is_focus = course_code %in% focus_codes) |>
    dplyr::filter(course_code %in% keep_codes)
}

traverse_from <- function(g, courses, depth, mode) {
  .validate_graph(g)
  .course_codes(courses, allow_empty = FALSE)
  if (!is.numeric(depth) || length(depth) != 1L || is.na(depth) || depth < 0 ||
      (is.finite(depth) && depth != floor(depth))) stop("depth must be a non-negative integer or Inf.", call. = FALSE)
  all_codes <- igraph::V(g)$course_code
  missing <- setdiff(courses, all_codes)
  if (length(missing) > 0) {
    stop(sprintf("Course code not found in graph: %s", paste(missing, collapse = ", ")))
  }
  
  idx <- match(courses, all_codes)
  
  order_val <- if (is.infinite(depth)) igraph::vcount(g) else depth
  
  reached <- igraph::ego(g, order = order_val, nodes = idx, mode = mode)
  unique(unlist(lapply(reached, function(v) v$course_code)))
}

#' Select exact course nodes
#'
#' Keeps only the supplied nodes and edges between them. Unknown or malformed codes raise an error.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param courses Character vector of course codes present in the graph, such as "CSSE1001".
#' @return A graph with focus markers.
#' @export
select_courses <- function(g, courses) {
  traverse_from(g, courses, depth = 0, mode = "all")
  build_subgraph(g, keep_codes = courses, focus_codes = courses)
}

#' Select upstream prerequisite context
#'
#' Traverses incoming edges of both relationship types. A flattened path does not evaluate AND/OR requirements.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param courses Character vector of course codes present in the graph, such as "CSSE1001".
#' @param depth Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses.
#' @return A graph containing the focus courses and reachable upstream nodes.
#' @export
select_ancestors <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "in")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}

#' Select downstream course pathways
#'
#' Traverses outgoing edges of both relationship types. Displayed courses may have additional requirements.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param courses Character vector of course codes present in the graph, such as "CSSE1001".
#' @param depth Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses.
#' @return A graph containing focus courses and reachable downstream nodes.
#' @export
select_descendants <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "out")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}

#' Select a local course neighborhood
#'
#' Traverses edges in either direction. At greater depths, sibling branches can be included.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param courses Character vector of course codes present in the graph, such as "CSSE1001".
#' @param depth Non-negative integer traversal distance, or Inf for all reachable nodes. Zero keeps only the focus courses.
#' @return A graph containing nodes within the requested undirected distance.
#' @export
select_neighborhood <- function(g, courses, depth = 2) {
  keep <- traverse_from(g, courses, depth, mode = "all")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}

#' Filter a graph by discipline
#'
#' Removes nonmatching nodes, potentially removing intermediate paths. Use plot highlighting to retain context.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param prefixes One or more four-letter uppercase discipline prefixes.
#' @return A graph, which may be empty if no prefix matches.
#' @export
select_by_prefix <- function(g, prefixes) {
  g <- tidygraph::as_tbl_graph(g)
  .validate_graph(g)
  if (!is.character(prefixes) || !length(prefixes) || anyNA(prefixes) || any(!grepl("^[A-Z]{4}$", prefixes)))
    stop("prefixes must contain four uppercase letters each.", call. = FALSE)
  g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(substr(course_code, 1, 4) %in% prefixes)
}

#' Save a static course network
#'
#' Renders a Sugiyama layout with relationship line styles, course status, and optional focus markers. Rejects empty selections. Parent directories are created automatically.
#'
#' @param g A directed igraph or tidygraph course graph with unique course_code attributes.
#' @param output_file Output file path. Parent directories are created when needed.
#' @param title Plot title.
#' @param highlight_prefix Optional discipline prefixes to emphasize without removing other nodes.
#' @param width Positive plot width in inches.
#' @param height Positive plot height in inches.
#' @param dpi Positive raster resolution in dots per inch.
#' @param seed Non-negative integer random seed for reproducible label placement. The caller's RNG state is restored.
#' @return The ggplot object invisibly; also saves the requested image.
#' @export
plot_course_graph <- function(g, output_file = "course_dependency_graph.png",
                              title = "Course Dependency Graph",
                              highlight_prefix = NULL,
                              width = 20, height = 13, dpi = 300, seed = 20260910) {
  
  .validate_graph(g)
  if (!igraph::vcount(g)) stop("Cannot plot an empty graph; revise the selection.", call. = FALSE)
  .number_scalar(seed, "seed", integer = TRUE)
  withr::local_seed(seed)
  .number_scalar(width, "width", 0.1)
  .number_scalar(height, "height", 0.1)
  .number_scalar(dpi, "dpi", 1)
  if (!"status" %in% igraph::vertex_attr_names(g)) g <- tag_course_status(g)
  if (!is.null(highlight_prefix)) {
    g <- g |>
      tidygraph::activate(nodes) |>
      dplyr::mutate(dimmed = !(substr(course_code, 1, 4) %in% highlight_prefix))
  } else {
    g <- g |> tidygraph::activate(nodes) |> dplyr::mutate(dimmed = FALSE)
  }
  
  node_df <- g |> tidygraph::activate(nodes) |> tibble::as_tibble()
  has_focus <- "is_focus" %in% names(node_df) && any(node_df$is_focus)
  
  node_alpha <- ifelse(node_df$dimmed, 0.45,
                       ifelse(node_df$status == "external", 0.55, 1))
  
  label_face <- ifelse(node_df$dimmed, "plain", "bold")
  
  p <- ggraph::ggraph(g, layout = "sugiyama") +
    ggraph::geom_edge_link(
      ggplot2::aes(linetype = edge_type),
      arrow = grid::arrow(length = grid::unit(1.8, "mm"), type = "closed"),
      end_cap = ggraph::circle(2.5, "mm"),
      start_cap = ggraph::circle(2.5, "mm"),
      alpha = 0.45, edge_width = 0.4, colour = "#607d8b"
    )
  
  if (has_focus) {
    p <- p +
      ggraph::geom_node_point(
        ggplot2::aes(fill = status, size = status, colour = is_focus),
        shape = 21, stroke = 1.6, alpha = node_alpha
      ) +
      ggplot2::scale_colour_manual(
        values = c("TRUE" = "#d84315", "FALSE" = "#90a4ae"),
        labels = c("TRUE" = "queried", "FALSE" = "related"),
        name = "Focus",
        guide = ggplot2::guide_legend(override.aes = list(fill = "#cfd8dc", size = 5, stroke = 1.6))
      )
  } else {
    p <- p +
      ggraph::geom_node_point(
        ggplot2::aes(fill = status, size = status),
        shape = 21, colour = "#455a64", stroke = 0.5, alpha = node_alpha
      )
  }
  
  p <- p +
    ggraph::geom_node_text(
      ggplot2::aes(label = course_code),
      repel = TRUE, family = "mono", size = 2.6,
      alpha = node_alpha, fontface = label_face, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = c(completed = "#66bb6a", current = "#42a5f5",
                 future = "#cfd8dc", external = "#f5f5f5"),
      name = "Status",
      guide = ggplot2::guide_legend(override.aes = list(colour = "#455a64", stroke = 0.5, size = 5))
    ) +
    ggplot2::scale_size_manual(
      values = c(completed = 6, current = 6, future = 6, external = 3),
      guide = "none"
    ) +
    ggplot2::labs(title = title) +
    ggraph::theme_graph(base_family = "sans") +
    ggplot2::theme(legend.position = "bottom")
  
  if (igraph::ecount(g) > 0L) p <- p + ggraph::scale_edge_linetype_manual(
    values = c(prerequisite = "solid", recommended_prerequisite = "dashed"), name = "Relation")
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(output_file, p, width = width, height = height, dpi = dpi, limitsize = FALSE)
  .plot_manifest(output_file, provenance = igraph::graph_attr(g, "provenance"),
    options = list(title = title, width = width, height = height, dpi = dpi, seed = seed,
      highlight_prefix = highlight_prefix, nodes = node_df[, intersect(c("course_code", "status", "is_focus"), names(node_df)), drop = FALSE],
      graph_sha256 = digest::digest(list(igraph::as_data_frame(g, what = "edges"), node_df), algo = "sha256")))
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

