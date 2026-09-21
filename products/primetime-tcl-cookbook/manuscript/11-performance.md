# Chapter 11. Performance and hygiene

A script that takes an hour gets run once a week. A script that takes a minute gets run after every change. This chapter is about the second kind.

## 11.1 Measure first

{{include:11_timing_util.tcl}}

`timeit` prints wall-clock time and resident memory before and after a block. Wrap the slow-looking part of any new script in it before optimising; the slow part is usually not the one you expect.

## 11.2 Patterns that are slow, and their fast equivalents

{{include:11_fast_patterns.tcl}}

The four rules behind these examples:

1. **One query, not N.** `get_timing_paths -to $collection` with a large `-max_paths` is one timer call. The same in a loop is N timer calls, each with its own setup cost.
2. **Filter in the query.** `-filter` runs inside the tool. A Tcl loop with `get_attribute` per object runs in the interpreter with a command dispatch per attribute.
3. **Attributes over paths when possible.** With `timing_save_pin_arrival_and_slack`, `max_slack` on a pin is a memory read. A path query is a graph traversal.
4. **Files over variables for large output.** `redirect -variable` builds the whole string in memory and then copies it again on assignment.

Two more that have no code example:

- `update_timing` is incremental after netlist edits. Do not call `update_timing -full` inside an ECO loop.
- `get_cells -hierarchical` with no filter on a full chip returns millions of objects. Always attach a `-filter` or a name pattern.

## 11.3 Log like a batch job

{{include:11_logging.tcl}}

Levels make a long log greppable: `grep ERROR run.log` is the whole post-mortem. `log_step` records the duration of each step so that when the batch takes twice as long as last week, the log says which step grew.

Flush after every line. A batch that is killed by the scheduler loses everything buffered since the last flush, which is exactly the part you need.

## 11.4 Script hygiene checklist

- Header with file name, author, purpose, tool, usage. Every script in this book has one; copy the format.
- No hard-coded paths inside procs. Paths go in a configuration block or in options.
- `-quiet` on every `get_*` and `get_attribute` where an empty result is legitimate. Without it, an empty result is an error message in the log and, with `sh_continue_on_error false`, a stopped batch.
- Return values, not just printed text. Every table proc here returns its rows.
- One proc per job. A proc that reports and fixes cannot be used to report only.
