# Concepts and data model

## Nodes and edges

A node represents a course code. An edge is directed from the course that has a requirement to the course named as its prerequisite. Following incoming edges moves backwards toward preparation. Following outgoing edges moves forwards toward courses that may be unlocked.

## Course table

`courses_info.csv` contains one row per course and fields extracted from the course page: name, level, school, units, contact hours, prerequisite text, recommended prerequisite text, and assessment methods.

## Edge table

`prereq_edges.csv` has three important columns:

| Column | Meaning |
| --- | --- |
| `course_code` | Course with the requirement |
| `prereq_code` | Course named by the requirement |
| `field` | `prerequisite` or `recommended_prerequisite` |

## Logic table

`prereq_logic.csv` stores the original expression and a JSON tree. Use this table when the distinction between AND and OR matters. The edge table intentionally flattens alternatives for graph traversal.

## External nodes

An external node is referenced by an edge but is absent from the selected plan. It is not an error. It tells you that a course depends on a course from another plan, school, or prerequisite pathway.

## Study status

`tag_course_status()` adds `completed`, `current`, `future`, and `external` statuses. Status is presentation metadata: it does not alter prerequisites or remove nodes.

## Two different kinds of filtering

A selector changes which nodes are in a returned subgraph. A plot highlight changes emphasis while retaining nodes. Use hard filtering to study a discipline in isolation. Use highlighting to preserve cross-discipline context.
