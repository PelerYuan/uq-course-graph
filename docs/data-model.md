# Data model

`courses_info.csv` stores one row per course. `prereq_edges.csv` stores directed prerequisite edges from a course to a prerequisite. `prereq_logic.csv` preserves parsed boolean trees as JSON. `manual_review.csv` stores expressions that require human interpretation. `graph_object.rds` stores the tidygraph object used by the visualization stage.
