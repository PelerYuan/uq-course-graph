# Stage 2: parse prerequisites

```r
run_stage("parse", config)
```

Input must be a successful scrape or an explicitly imported snapshot. The managed stage checks that its source file still matches the recorded checksum. Both `prerequisite` and `recommended_prerequisite` columns must exist; an empty field means no text was supplied, not a verified absence of every academic rule.

The grammar supports course codes, explicit AND/OR operators, and parentheses. AND binds more tightly than OR. Bare commas, free text, missing operands, and unmatched parentheses enter the review queue. A trailing period or semicolon and a comma immediately followed by an explicit conjunction are supported.

Outputs retain headers even when they contain no rows. Automatic base tables end in `_auto.csv`; canonical tables omit that suffix and are subsequently updated by review. Re-parsing regenerates canonical tables, so always rerun review before graph construction.

See the [parsing reference](../reference/parsing.md) and [review walkthrough](review.md).
