# Carried files

Each file below comes from tot at the sha in PIN.  The first line of each
file names its origin and its delta.  The count is the number of lines
that `diff` prints between `git -C vendor/tot show ORIGIN` and the file.
dev/carry-check.sh recomputes every count and fails when one differs.

| file | origin | diff lines |
| --- | --- | --- |
| lib/level.ml | 8cf0b8b:lib/level.ml | 2 |
| lib/level.mli | 8cf0b8b:lib/level.mli | 2 |
| lib/quantity.ml | 8cf0b8b:lib/quantity.ml | 2 |
| lib/literal.ml | 8cf0b8b:lib/literal.ml | 2 |
| lib/global.ml | 8cf0b8b:lib/global.ml | 126 |
| lib/budget.ml | 8cf0b8b:lib/budget.ml | 2 |
| lib/budget.mli | 8cf0b8b:lib/budget.mli | 2 |

A count of 2 is the carry header line and nothing else.  lib/global.ml
also drops the Ind, Ctor and Prim entries with their five views, because
those name modules that arrive at Stage B.  Stage B adapts lib/global.ml
again and updates its count here.
