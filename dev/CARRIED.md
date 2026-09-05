# Carried files

Each file below comes from tot at the sha in PIN.  The first line of each
file names its origin and its delta.  The count is the number of lines
that `diff` prints between `git -C vendor/tot show ORIGIN` and the file.
dev/carry-check.sh recomputes every count and fails when one differs.

| file | origin | diff lines |
| --- | --- | --- |
| lib/level.ml | 8cf0b8b:lib/level.ml | 2 |
| lib/level.mli | 8cf0b8b:lib/level.mli | 2 |
| lib/quantity.ml | 8cf0b8b:lib/quantity.ml | 34 |
| lib/literal.ml | 8cf0b8b:lib/literal.ml | 2 |
| lib/global.ml | 8cf0b8b:lib/global.ml | 164 |
| lib/budget.ml | 8cf0b8b:lib/budget.ml | 2 |
| lib/budget.mli | 8cf0b8b:lib/budget.mli | 2 |

A count of 2 is the carry header line and nothing else.

lib/quantity.ml is at 34 because Stage B adds the third mark One between
Zero and Many (SB-D3), with its arm in mul, in equal and in to_string.
The surface reads One from the '1' binder mark and the M0 checker counts
it as Many, so the linear counter is the M1 obligation SPEC.md section 10
records.

lib/global.ml is at 164.  It drops the Ind and Ctor entries with their
views, because the recursive shapes arrive at M1, and Stage B re-adapts
the Prim entry with prim_of, find_prim and initial.  initial holds Nat at
Type 0 and the five primitives of lib/prim.ml at the types of SB-D8.
