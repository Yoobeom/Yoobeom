# Chapter 9. Reporting and data export

PrimeTime reports are written for a human reading one path. Tracking a project over 50 runs needs machine-readable output: CSV for spreadsheets and diffs, JSON for dashboards. Pure Tcl is enough for both; no package needs to be installed in pt_shell.

## 9.1 CSV and JSON in pure Tcl

{{include:09_csv_json.tcl}}

`csv_field` quotes only when needed, so files stay readable. `read_csv` handles quoted fields with embedded commas, which appear when a pin name contains a comma from a generate block.

`json_val` emits numbers unquoted so downstream tools get numeric types. The `0?*` guard keeps values like `007` as strings, since a leading zero is not valid JSON for a number.

## 9.2 One JSON per run

{{include:09_signoff_summary.tcl}}

The file holds design, mode, corner, tool version, timestamp, per-path-group WNS/TNS/violator counts for setup and hold, and the DRV count. Any dashboard, wiki bot or spreadsheet import can read it. A directory of these files, one per run, is a complete timing history of a project.

`get_path_groups` returns the groups the timer uses, including the default group and any created with `group_path`. Iterating over groups rather than clocks matches what `report_timing` does by default.

## 9.3 Diff two runs

{{include:09_run_diff.tcl}}

The input is any CSV with `slack` and `endpoint` columns, so the violator CSV from Chapter 7 works directly. Endpoints present only in the new file are new violators; endpoints present only in the old file were fixed (or moved above the slack threshold). The degraded list is what a reviewer wants first after an ECO or a netlist drop.

The last block makes the file runnable with `tclsh` outside PrimeTime, so a continuous integration job can produce the diff without a licence.

## 9.4 report_timing bundles

Every team argues about report_timing options until someone writes them down. These procs are the written-down version: one full-detail report for path review, one end-only report for tracking, one PBA report for pre-ECO confirmation.

{{include:09_custom_report_timing.tcl}}

`-path_type full_clock_expanded` shows the clock network stage by stage, which is needed to see where launch and capture latency diverge. `-derate` and `-crpr` add columns showing the derate factor and the CRPR credit, so a reviewer does not have to infer them.

`rt_all_groups` writes setup, hold and end-only reports for every group with a filename-safe group name. `**default**` becomes `all_default_all`, which is ugly but unambiguous.
