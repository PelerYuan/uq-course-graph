library(tidygraph)
library(ggraph)
library(igraph)
library(dplyr)


# ============================================================
# ============================================================

#'
#'
#'
tag_course_status <- function(g, completed = character(), current = character()) {
  g %>%
    activate(nodes) %>%
    mutate(status = case_when(
      course_code %in% completed ~ "completed",
      course_code %in% current   ~ "current",
      is.na(course_name)         ~ "external",
      TRUE                       ~ "future"
    ))
}


# ============================================================
#
# ============================================================

#'
#' @param g tbl_graph
build_subgraph <- function(g, keep_codes, focus_codes) {
  g %>%
    activate(nodes) %>%
    mutate(is_focus = course_code %in% focus_codes) %>%
    filter(course_code %in% keep_codes)
}


#'
#'
#' @param g tbl_graph
traverse_from <- function(g, courses, depth, mode) {
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


#'
#' @param g tbl_graph
select_courses <- function(g, courses) {
  build_subgraph(g, keep_codes = courses, focus_codes = courses)
}


#'
#' @param g tbl_graph
select_ancestors <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "in")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#'
#' @param g tbl_graph
select_descendants <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "out")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#'
#'
#' @param g tbl_graph
select_neighborhood <- function(g, courses, depth = 2) {
  keep <- traverse_from(g, courses, depth, mode = "all")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#'
#'
#' @param g tbl_graph
select_by_prefix <- function(g, prefixes) {
  g %>%
    activate(nodes) %>%
    filter(substr(course_code, 1, 4) %in% prefixes)
}


# ============================================================
# ============================================================

#'
#'
#'
plot_course_graph <- function(g, output_file = "course_dependency_graph.png",
                              title = "Course Dependency Graph",
                              highlight_prefix = NULL,
                              width = 20, height = 13, dpi = 300) {
  
  if (!is.null(highlight_prefix)) {
    g <- g %>%
      activate(nodes) %>%
      mutate(dimmed = !(substr(course_code, 1, 4) %in% highlight_prefix))
  } else {
    g <- g %>% activate(nodes) %>% mutate(dimmed = FALSE)
  }
  
  node_df <- g %>% activate(nodes) %>% as_tibble()
  has_focus <- "is_focus" %in% names(node_df) && any(node_df$is_focus)
  
  node_alpha <- ifelse(node_df$dimmed, 0.45,
                       ifelse(node_df$status == "external", 0.55, 1))
  
  label_face <- ifelse(node_df$dimmed, "plain", "bold")
  
  p <- ggraph(g, layout = "sugiyama") +
    geom_edge_link(
      aes(linetype = edge_type),
      arrow = arrow(length = unit(1.8, "mm"), type = "closed"),
      end_cap = circle(2.5, "mm"),
      start_cap = circle(2.5, "mm"),
      alpha = 0.45, edge_width = 0.4, colour = "#607d8b"
    )
  
  if (has_focus) {
    p <- p +
      geom_node_point(
        aes(fill = status, size = status, colour = is_focus),
        shape = 21, stroke = 1.6, alpha = node_alpha
      ) +
      scale_colour_manual(
        values = c("TRUE" = "#d84315", "FALSE" = "#90a4ae"),
        labels = c("TRUE" = "queried", "FALSE" = "related"),
        name = "Focus",
        guide = guide_legend(override.aes = list(fill = "#cfd8dc", size = 5, stroke = 1.6))
      )
  } else {
    p <- p +
      geom_node_point(
        aes(fill = status, size = status),
        shape = 21, colour = "#455a64", stroke = 0.5, alpha = node_alpha
      )
  }
  
  p <- p +
    geom_node_text(
      aes(label = course_code),
      repel = TRUE, family = "mono", size = 2.6,
      alpha = node_alpha, fontface = label_face, show.legend = FALSE
    ) +
    scale_fill_manual(
      values = c(completed = "#66bb6a", current = "#42a5f5",
                 future = "#cfd8dc", external = "#f5f5f5"),
      name = "Status",
      guide = guide_legend(override.aes = list(colour = "#455a64", stroke = 0.5, size = 5))
    ) +
    scale_size_manual(
      values = c(completed = 6, current = 6, future = 6, external = 3),
      guide = "none"
    ) +
    scale_edge_linetype_manual(
      values = c(prerequisite = "solid", recommended_prerequisite = "dashed"),
      name = "Relation"
    ) +
    labs(title = title) +
    theme_graph(base_family = "sans") +
    theme(legend.position = "bottom")
  
  ggsave(output_file, p, width = width, height = height, dpi = dpi, limitsize = FALSE)
  cat(sprintf("Saved to %s\n", output_file))
  invisible(p)
}

