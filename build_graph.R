library(tidygraph)
library(igraph)
library(dplyr)


#' 构建课程依赖图
#'
#' 边的方向是 prereq_code -> course_code,箭头表示"这门前置课解锁了后面这门课",
#' 这样顺着箭头方向走就是正常的修课顺序
#'
#' 只用 prerequisite(硬性前置)字段建主图;recommended_prerequisite
#' 属于建议而非强制要求,单独保留在 edge_type 列里,不参与环检测和拓扑排序
#'
#' @param courses_file courses_info.csv 路径
#' @param edges_file prereq_edges.csv 路径
#' @return 一个 tbl_graph 对象
build_course_graph <- function(courses_file = "courses_info.csv",
                                edges_file = "prereq_edges.csv") {

  courses <- read.csv(courses_file, stringsAsFactors = FALSE)
  edges_raw <- read.csv(edges_file, stringsAsFactors = FALSE)

  nodes <- courses %>% distinct(course_code, .keep_all = TRUE)

  # 有些前置课程代码可能不在这个专业的课程列表里
  # (比如前置课属于别的专业),这些也要作为节点补进去,否则建图会报错
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


#' 检测图中是否存在环
#'
#' 前置关系理论上必须是 DAG(无环),如果检测到环,大概率是数据抓取/解析出了错
#' (比如误把某门课的"incompatible"当成了"prerequisite"),而不是真的存在
#' 循环依赖的课程 —— UQ 不会允许 A 的前置是 B,B 的前置又是 A
#'
#' @param g build_course_graph() 的输出
#' @return TRUE/FALSE,若为 FALSE 会额外打印涉及环的课程代码
check_dag <- function(g) {
  is_dag <- igraph::is_dag(g)
  cat(sprintf("Is DAG: %s\n", is_dag))

  if (!is_dag) {
    # 强连通分量里节点数 > 1 的,就是环所涉及的节点
    scc <- igraph::components(g, mode = "strong")
    cyclic_ids <- which(scc$csize[scc$membership] > 1)
    cyclic_codes <- igraph::V(g)$course_code[cyclic_ids]
    cat("Cycle detected, involved courses:\n")
    print(unique(cyclic_codes))
  }

  is_dag
}


#' 计算每门课的关键程度排名
#'
#' - out_degree:直接解锁了多少门课(一步之遥)
#' - downstream_count:顺着依赖链能到达的下游课程总数(所有间接解锁的课都算上),
#'   这个数字更能反映"这门课有多关键"——因为很多课不是直接前置,而是前置的前置
#'
#' @param g build_course_graph() 的输出
#' @return 按 downstream_count 降序排列的 data.frame
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


# ===== 调用函数 =====

if (!exists(".sourced_as_library")) {
  g <- build_course_graph()
  check_dag(g)

  key_courses <- rank_key_courses(g)
  write.csv(key_courses, "key_courses.csv", row.names = FALSE)
  saveRDS(g, "graph_object.rds")

  cat("Graph saved to graph_object.rds\n")
  cat("Key course ranking saved to key_courses.csv\n\n")
  print(head(key_courses, 10))
}
