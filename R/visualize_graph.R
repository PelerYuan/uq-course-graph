library(tidygraph)
library(ggraph)
library(igraph)
library(dplyr)


# ============================================================
# 状态标注
# ============================================================

#' 给图里每门课标注状态(已修完 / 当前学期 / 未来计划 / 外部引用)
#'
#' 有些课程代码只是被专业内课程当前置引用,本身不在这个专业的课程列表里
#' (course_name 是 NA),这类标成 "external"——图上依然显示,只是弱化样式,
#' 不跟专业本身的课程抢视觉重点
#'
#' 两个参数都不传的话,所有课都是 future/external,图上就没有绿蓝配色,
#' 适合只想看纯粹依赖结构的场合
#'
#' @param g build_graph.R 生成的 tbl_graph 对象
#' @param completed 已修完的课程代码向量
#' @param current 当前学期在修的课程代码向量
#' @return 加了 status 列的 tbl_graph
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
# 子图选择器
#
# 四个选择器都返回新的 tbl_graph,并在节点上加一列 is_focus 标记
# "这是你查询时点名的课",绘图时会用红色描边高亮出来。
# 都可以用管道串起来: g %>% select_ancestors("CSSE3010") %>% plot_course_graph()
# ============================================================

#' 内部函数:按节点名取子图,并标记哪些是查询焦点
#'
#' @param g tbl_graph
#' @param keep_codes 要保留的课程代码向量
#' @param focus_codes 其中属于"查询焦点"的课程代码
#' @return 子图 tbl_graph
build_subgraph <- function(g, keep_codes, focus_codes) {
  g %>%
    activate(nodes) %>%
    mutate(is_focus = course_code %in% focus_codes) %>%
    filter(course_code %in% keep_codes)
}


#' 内部函数:沿指定方向做有限深度的遍历
#'
#' igraph::subcomponent() 只能一路走到底,没法限制深度,
#' 所以用 ego() 来支持 depth 参数(order = depth)
#'
#' @param g tbl_graph
#' @param courses 起点课程代码向量
#' @param depth 遍历深度,Inf 表示一路到底
#' @param mode "in" = 上游前置, "out" = 下游解锁, "all" = 双向
#' @return 可达节点的课程代码向量(含起点自身)
traverse_from <- function(g, courses, depth, mode) {
  all_codes <- igraph::V(g)$course_code
  missing <- setdiff(courses, all_codes)
  if (length(missing) > 0) {
    stop(sprintf("Course code not found in graph: %s", paste(missing, collapse = ", ")))
  }
  
  idx <- match(courses, all_codes)
  
  # ego() 的 order 参数不接受 Inf,用节点总数代替(等价于无限深度)
  order_val <- if (is.infinite(depth)) igraph::vcount(g) else depth
  
  reached <- igraph::ego(g, order = order_val, nodes = idx, mode = mode)
  unique(unlist(lapply(reached, function(v) v$course_code)))
}


#' 只画指定的这几门课(以及它们之间已有的连线)
#'
#' @param g tbl_graph
#' @param courses 课程代码向量
#' @return 子图
select_courses <- function(g, courses) {
  build_subgraph(g, keep_codes = courses, focus_codes = courses)
}


#' 指定课程 + 它们的上游前置课程(要修这些课,得先修什么)
#'
#' @param g tbl_graph
#' @param courses 课程代码向量
#' @param depth 往上追溯几层,默认 Inf(一路追到根)
#' @return 子图
select_ancestors <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "in")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#' 指定课程 + 它们的下游课程(修完这些课能解锁什么)
#'
#' @param g tbl_graph
#' @param courses 课程代码向量
#' @param depth 往下延伸几层,默认 Inf(一路到叶子)
#' @return 子图
select_descendants <- function(g, courses, depth = Inf) {
  keep <- traverse_from(g, courses, depth, mode = "out")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#' 指定课程 + 上下游全部关联课程(完整的关联网络)
#'
#' 注意 mode="all" 会顺着边的两个方向乱窜,depth 设大了很容易
#' 把整张图都拉进来,建议配合较小的 depth 使用
#'
#' @param g tbl_graph
#' @param courses 课程代码向量
#' @param depth 向外扩展几层,默认 2
#' @return 子图
select_neighborhood <- function(g, courses, depth = 2) {
  keep <- traverse_from(g, courses, depth, mode = "all")
  build_subgraph(g, keep_codes = keep, focus_codes = courses)
}


#' 按课程代码前缀筛选(只保留指定学科的课程)
#'
#' 跟上面几个选择器不同,这个是"硬过滤",不匹配的课程直接从图里移除。
#' 如果只是想让某些学科更醒目、但保留其他课程作为背景,
#' 用 plot_course_graph(highlight_prefix = ...) 那个参数,不要用这个
#'
#' @param g tbl_graph
#' @param prefixes 4位前缀向量,如 c("ENGG", "ELEC")
#' @return 子图
select_by_prefix <- function(g, prefixes) {
  g %>%
    activate(nodes) %>%
    filter(substr(course_code, 1, 4) %in% prefixes)
}


# ============================================================
# 绘图
# ============================================================

#' 画课程依赖图,存成图片
#'
#' 三个视觉维度互不冲突,可以叠加使用:
#'   - 填充色     = 修读状态(已修完绿 / 当前蓝 / 未来灰 / 外部浅白)
#'   - 红色粗描边 = 查询焦点(用 select_* 时点名的那几门课)
#'   - 淡化       = 不匹配 highlight_prefix 的课程,退到背景
#'
#' 边线型区分 prerequisite(硬性,实线)和 recommended_prerequisite(建议,虚线)。
#' 没有把 AND/OR 逻辑编码进线型——那个信息只在 prereq_logic.csv 的嵌套树里,
#' 拍平成边表后已经丢失了每条边属于哪个 AND/OR 分组这个细节
#'
#' @param g 标注好 status 的 tbl_graph(可以是子图)
#' @param output_file 输出图片路径
#' @param title 图表标题
#' @param highlight_prefix 要突出显示的4位课程前缀向量,如 c("ENGG","ELEC");
#'   不传则所有课程正常显示
#' @param width,height 图片尺寸(英寸),节点少时可以调小
#' @param dpi 分辨率,默认 300
plot_course_graph <- function(g, output_file = "course_dependency_graph.png",
                              title = "Course Dependency Graph",
                              highlight_prefix = NULL,
                              width = 20, height = 13, dpi = 300) {
  
  # 前缀高亮:不匹配的节点淡化,匹配的保持原有配色
  # 单独用一列 dimmed 控制透明度,不动 status 和 is_focus,三者互不干扰
  if (!is.null(highlight_prefix)) {
    g <- g %>%
      activate(nodes) %>%
      mutate(dimmed = !(substr(course_code, 1, 4) %in% highlight_prefix))
  } else {
    g <- g %>% activate(nodes) %>% mutate(dimmed = FALSE)
  }
  
  node_df <- g %>% activate(nodes) %>% as_tibble()
  has_focus <- "is_focus" %in% names(node_df) && any(node_df$is_focus)
  
  # external 节点本来就该弱化,跟前缀淡化叠加起来算最终透明度
  # 淡化到 0.45 而不是更低,保证淡化的节点仍能看清位置和连线,只是不抢眼
  node_alpha <- ifelse(node_df$dimmed, 0.45,
                       ifelse(node_df$status == "external", 0.55, 1))
  
  # 被高亮的课程标签加粗,进一步拉开区分度
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

