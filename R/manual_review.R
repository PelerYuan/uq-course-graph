library(dplyr)
library(stringr)
library(tibble)
library(jsonlite)

.sourced_as_library <- TRUE
source("parse_prerequisites.R")
rm(.sourced_as_library)  # 用完立刻清理,避免这个变量残留在 session 里影响后面 source 的其他脚本


#' 用 R 原生弹窗交互式填写修正模板(替代打开 Excel 手改 csv)
#'
#' edit() 是 base R 自带的表格编辑器:Windows 上弹出系统原生数据编辑窗口,
#' 改完关闭窗口后作为新的 data.frame 返回。Mac 上依赖 X11/XQuartz。
#'
#' @param manual_review_file manual_review.csv 路径
#' @param output_file 保存修正模板的路径
#' @return 编辑后的 data.frame(已同时写入 output_file)
review_manually <- function(manual_review_file = "manual_review.csv",
                             output_file = "manual_review_template.csv") {
  review <- read.csv(manual_review_file, stringsAsFactors = FALSE)
  review$cleaned_text <- NA_character_
  review$note <- NA_character_

  cat("Opening data editor window. Fill in 'cleaned_text' and 'note' columns.\n")
  cat("Leave cleaned_text blank for entries that cannot be expressed as course codes.\n")
  cat("Close the editor window when done.\n")

  edited <- edit(review)

  write.csv(edited, output_file, row.names = FALSE)
  cat(sprintf("Saved to %s\n", output_file))

  edited
}


#' 从 manual_review.csv 生成一份人工填写模板(Excel 手改路线,edit() 不可用时的备用方案)
#'
#' 在模板里新增两列:
#'   cleaned_text —— 你手动改写后的、纯课程代码的布尔表达式(能解析就填这个)
#'   note         —— 备注,说明原文里被去掉的部分,或者为什么这条没法转成课程依赖
#'
#' cleaned_text 留空 = 判定这条前置条件本质上无法用课程依赖表示(比如"修满32学分"),
#' 会被归档到 special_requirements.csv,而不是强行编个假的课程代码进图里
#'
#' @param manual_review_file manual_review.csv 路径
#' @param output_file 模板输出路径
generate_review_template <- function(manual_review_file = "manual_review.csv",
                                      output_file = "manual_review_template.csv") {
  review <- read.csv(manual_review_file, stringsAsFactors = FALSE)
  review$cleaned_text <- NA_character_
  review$note <- NA_character_

  write.csv(review, output_file, row.names = FALSE)
  cat(sprintf("Template saved to %s (%d rows to fill in)\n", output_file, nrow(review)))
  review
}


#' 把人工填写好的模板合并回 prereq_edges.csv / prereq_logic.csv
#'
#' - cleaned_text 有内容的行:重新走一遍解析器,结果追加进 edges/logic
#' - cleaned_text 留空的行:归档进 special_requirements.csv,保留 note 里的说明
#'
#' @param template_file 填写好的模板路径
#' @param edges_file 现有 prereq_edges.csv 路径
#' @param logic_file 现有 prereq_logic.csv 路径
#' @param special_file 输出的特殊要求清单路径
apply_manual_overrides <- function(template_file = "manual_review_template.csv",
                                    edges_file = "prereq_edges.csv",
                                    logic_file = "prereq_logic.csv",
                                    special_file = "special_requirements.csv") {

  template <- read.csv(template_file, stringsAsFactors = FALSE)
  edges <- read.csv(edges_file, stringsAsFactors = FALSE)
  logic <- read.csv(logic_file, stringsAsFactors = FALSE)

  special_rows <- list()
  new_edges <- list()
  new_logic <- list()

  for (i in seq_len(nrow(template))) {
    row <- template[i, ]
    cleaned <- row$cleaned_text

    if (is.na(cleaned) || identical(str_trim(cleaned), "")) {
      special_rows[[length(special_rows) + 1]] <- tibble(
        course_code = row$course_code, field = row$field,
        raw_text = row$raw_text, note = row$note
      )
      next
    }

    if (!is_clean_prereq(cleaned)) {
      stop(sprintf(
        "Row %d (%s / %s): cleaned_text still contains free text, please simplify further: %s",
        i, row$course_code, row$field, cleaned
      ))
    }

    tree <- parse_prereq_expr(tokenize_prereq(cleaned))
    codes <- unique(flatten_prereq_codes(tree))
    tree_json <- as.character(toJSON(tree, auto_unbox = TRUE))

    new_logic[[length(new_logic) + 1]] <- tibble(
      course_code = row$course_code, field = row$field,
      raw_text = row$raw_text, logic_tree = tree_json
    )

    for (code in codes) {
      new_edges[[length(new_edges) + 1]] <- tibble(
        course_code = row$course_code, prereq_code = code, field = row$field
      )
    }
  }

  edges <- bind_rows(edges, bind_rows(new_edges))
  logic <- bind_rows(logic, bind_rows(new_logic))
  special <- bind_rows(special_rows)

  write.csv(edges, edges_file, row.names = FALSE)
  write.csv(logic, logic_file, row.names = FALSE)
  write.csv(special, special_file, row.names = FALSE)

  cat(sprintf("Merged %d manually-cleaned entries into edges/logic\n", length(new_logic)))
  cat(sprintf("Archived %d entries to %s as non-course requirements\n", nrow(special), special_file))
}

