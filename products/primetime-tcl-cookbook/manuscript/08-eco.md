# Chapter 8. ECO scripting

PrimeTime can size cells and insert buffers in its own netlist view, re-time incrementally, and write the changes out for the implementation tool. This chapter covers the three ECO tasks that are worth scripting: choosing what to change, applying the change with a check that it helped, and exporting it.

All scripts in this chapter need the ECO capability. `size_cell`, `insert_buffer`, `remove_buffer`, `write_changes`, `fix_eco_timing` and `fix_eco_drc` are not available without it.

## 8.1 Choosing sizing candidates

Automatic fixers pick candidates by their own cost function. A scripted candidate list lets you apply your own rules: skip clock cells, skip delay cells, skip anything marked dont_touch, and rank by the number of failing paths that would benefit.

{{include:08_eco_candidates.tcl}}

For each failing path, the cell with the slowest output transition (excluding registers and skipped types) is nominated. A cell nominated by many paths rises to the top. `get_alternative_lib_cells` returns the lib cells that are footprint- or function-compatible according to the library, so the last column says whether an upsizing is even possible.

The `-min_slack` option ignores paths worse than the given value. Paths at minus 500 ps will not be fixed by sizing one cell; leave them for a logic change and keep the ECO list to what sizing can fix.

## 8.2 Try, measure, keep or revert

{{include:08_eco_upsize.tcl}}

The loop is deliberately conservative: one cell at a time, one `update_timing` per attempt, keep only if the worst slack through the cell improves by more than 1 ps. On a block with a few hundred candidates it runs in minutes because incremental `update_timing` after `size_cell` re-times only the affected cone.

The drive strength is read from the lib cell name with a regular expression that matches `X4`, `D8` and similar suffixes. Change `drive_of` to match your library's naming convention. If the library provides a drive strength attribute on lib cells, use that instead.

The revert path resolves the original lib cell with `get_lib_cells */$old_ref`, which assumes the base name is unique across linked libraries. Multi-library flows with the same cell name in two libraries should keep the full `lib/cell` name from `get_attribute $cell lib_cell` instead.

## 8.3 Hold fixing with a setup guard

Hold buffers inserted without checking setup slack are the classic way to turn a hold violation into a setup violation. `fix_hold_by_buffer` computes the number of buffers needed from the hold slack, estimates the cost with a per-buffer delay you supply, and skips the endpoint when the setup slack cannot absorb it.

{{include:08_hold_buffer.tcl}}

`-buf_delay` is an estimate used only for the setup guard; the timer computes the real delay after insertion. Set it to the typical delay of the chosen delay cell in the hold corner. The proc processes each endpoint once (`done` array) because `get_timing_paths` may return several paths to the same endpoint when `-nworst 1` is combined with multiple launch clocks.

## 8.4 Export for the implementation tool

{{include:08_write_eco.tcl}}

`write_changes -format icctcl` produces commands IC Compiler II reads directly. For Innovus the script translates the `ptsh` format line by line: `size_cell` becomes `ecoChangeCell`, `insert_buffer` becomes `ecoAddRepeater`. Check the generated file against the Innovus version in use; option names have changed across releases.

The post-ECO `report_qor` and `report_global_timing` are the numbers to put in the ECO sign-off note next to the pre-ECO numbers from the same procs.

## 8.5 Using fix_eco_timing with before/after metrics

When the built-in fixer is acceptable, the value of a wrapper is the measurement around it: WNS, TNS and violator count before and after, printed together.

{{include:08_fix_eco_wrapper.tcl}}

Run `drc` first, then `setup`, then `hold`. Fixing DRV first often improves setup on its own; fixing hold last avoids re-breaking hold with setup upsizing. After the three passes, run `export_eco`.
