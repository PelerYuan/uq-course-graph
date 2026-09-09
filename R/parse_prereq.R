library(dplyr)
library(stringr)
library(tibble)
library(jsonlite)

# ============================================================
# 可解析性检查
# ============================================================

#' 检查前置条件文本是否为纯课程代码布尔表达式
#'
#' 把课程代码、and/or、括号、逗号这些合法 token 全部去掉,
#' 如果还剩下实质性文字,说明混入了自由文本(如"32 units"、
#' "Year 12"这类描述性要求),判定为不可解析
#'
#' @param text 原始前置条件文本
#' @return TRUE/FALSE
is_clean_prereq <- function(text) {
  remainder <- text
  remainder <- str_remove_all(remainder, "[A-Z]{4}\\d{4}")
  remainder <- str_remove_all(remainder, regex("\\b(and|or)\\b", ignore_case = TRUE))
  remainder <- str_remove_all(remainder, "[(),.;]")
  remainder <- str_squish(remainder)
  nchar(remainder) == 0
}


# ============================================================
# 分词与解析
# ============================================================

#' 把前置条件文本切分成 token 序列
#'
#' 逗号视为 or 的同义写法;and/or 统一转小写,课程代码保持原样
#'
#' @param text 已通过 is_clean_prereq 检查的文本
#' @return 字符向量,如 c("ENGG1300","and","(","MATH1051","or","MATH1071",")")
tokenize_prereq <- function(text) {
  # 先合并 ", or" 这种写法,避免产生重复的 or token
  text <- str_replace_all(text, ",\\s*(?i)or\\b", " or")
  # 剩余的裸逗号也当作 or 处理
  text <- str_replace_all(text, ",", " or ")

  tokens <- str_extract_all(text, "\\(|\\)|[A-Z]{4}\\d{4}|(?i)\\b(?:and|or)\\b")[[1]]

  # 课程代码保持原样,and/or 统一转小写
  ifelse(str_detect(tokens, "^[A-Z]{4}\\d{4}$"), tokens, str_to_lower(tokens))
}


#' 递归下降解析器:把 token 序列解析成嵌套 AND/OR 树
#'
#' 文法(优先级从低到高):
#'   expr := term ("or" term)*
#'   term := factor ("and" factor)*
#'   factor := "(" expr ")" | 课程代码
#'
#' 叶子节点是课程代码字符串;内部节点是 list(op="and"/"or", args=list(...))
#'
#' @param tokens tokenize_prereq() 的输出
#' @return 嵌套 list 结构,或单个课程代码字符串(无逻辑运算时)
parse_prereq_expr <- function(tokens) {
  pos <- 1
  n <- length(tokens)

  peek <- function() if (pos <= n) tokens[pos] else NA
  advance <- function() pos <<- pos + 1

  parse_factor <- function() {
    tok <- peek()
    if (identical(tok, "(")) {
      advance()
      node <- parse_expr()
      if (!identical(peek(), ")")) stop("expected closing paren")
      advance()
      return(node)
    }
    advance()
    tok  # 叶子节点:课程代码
  }

  parse_term <- function() {
    args <- list(parse_factor())
    while (identical(peek(), "and")) {
      advance()
      args <- c(args, list(parse_factor()))
    }
    if (length(args) == 1) return(args[[1]])
    list(op = "and", args = args)
  }

  parse_expr <- function() {
    args <- list(parse_term())
    while (identical(peek(), "or")) {
      advance()
      args <- c(args, list(parse_term()))
    }
    if (length(args) == 1) return(args[[1]])
    list(op = "or", args = args)
  }

  result <- parse_expr()
  if (pos <= n) stop("unconsumed tokens remain")
  result
}


#' 展平逻辑树,取出其中提到的所有课程代码(不含逻辑关系,仅用于建图)
#'
#' @param node parse_prereq_expr() 的输出
#' @return 课程代码字符向量
flatten_prereq_codes <- function(node) {
  if (is.character(node)) return(node)
  unlist(lapply(node$args, flatten_prereq_codes))
}


# ============================================================
# 主流程
# ============================================================

#' 批量解析 courses_info 里的 prerequisite / recommended_prerequisite 字段
#'
#' @param courses_info 含 course_code、prerequisite、recommended_prerequisite 列的 data.frame
#' @param output_dir 输出目录
#' @return list(edges, logic, manual_review) 三个 data.frame
parse_all_prerequisites <- function(courses_info, output_dir = ".") {

  edges <- list()
  logic_rows <- list()
  manual_review <- list()

  fields <- c("prerequisite", "recommended_prerequisite")

  for (i in seq_len(nrow(courses_info))) {
    course <- courses_info$course_code[i]

    for (field in fields) {
      raw <- courses_info[[field]][i]
      if (is.na(raw) || identical(str_trim(raw), "")) next

      if (!is_clean_prereq(raw)) {
        manual_review[[length(manual_review) + 1]] <- tibble(
          course_code = course, field = field, raw_text = raw, reason = "contains_free_text"
        )
        next
      }

      tree <- tryCatch(
        parse_prereq_expr(tokenize_prereq(raw)),
        error = function(e) e
      )

      if (inherits(tree, "error")) {
        manual_review[[length(manual_review) + 1]] <- tibble(
          course_code = course, field = field, raw_text = raw,
          reason = paste("parse_error:", conditionMessage(tree))
        )
        next
      }

      codes <- unique(flatten_prereq_codes(tree))
      # toJSON() 返回带 "json" S3 类的对象,多行 bind_rows 时类型会冲突,
      # 转成普通字符串存储
      tree_json <- as.character(toJSON(tree, auto_unbox = TRUE))

      logic_rows[[length(logic_rows) + 1]] <- tibble(
        course_code = course, field = field,
        raw_text = raw, logic_tree = tree_json
      )

      for (code in codes) {
        edges[[length(edges) + 1]] <- tibble(
          course_code = course, prereq_code = code, field = field
        )
      }
    }
  }

  edges_df <- bind_rows(edges)
  logic_df <- bind_rows(logic_rows)
  manual_review_df <- bind_rows(manual_review)

  write.csv(edges_df, file.path(output_dir, "prereq_edges.csv"), row.names = FALSE)
  write.csv(logic_df, file.path(output_dir, "prereq_logic.csv"), row.names = FALSE)
  write.csv(manual_review_df, file.path(output_dir, "manual_review.csv"), row.names = FALSE)

  cat(sprintf(
    "Parsed %d entries successfully, %d flagged for manual review\n",
    nrow(logic_df), nrow(manual_review_df)
  ))
  cat(sprintf("Edges: %d, saved to prereq_edges.csv\n", nrow(edges_df)))
  cat("Logic trees saved to prereq_logic.csv\n")
  cat("Manual review items saved to manual_review.csv\n")

  list(edges = edges_df, logic = logic_df, manual_review = manual_review_df)
}

