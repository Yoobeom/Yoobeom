# Introduction

## Who this book is for

You run PrimeTime every day. You know what `report_timing` prints and you know what a negative slack means. What slows you down is the gap between "I need the worst path per clock pair across 30 blocks" and a script that actually produces that table in ten seconds.

This book closes that gap with 41 scripts that are already written, already debugged against real designs, and organised the way a signoff flow is organised: session setup, design queries, path analysis, clock checks, constraint audit, violation triage, ECO, reporting, multi-scenario, and performance.

Every script is a standalone `.tcl` file with a header, a `proc` you can source into any session, and a usage line. The chapters explain why each script is written the way it is, what PrimeTime behaviour it depends on, and where it breaks.

## What you need

- PrimeTime (any release from the last several years; attribute names that vary between releases are called out)
- A linked design with parasitics and constraints loaded
- Tcl 8.5 or later (bundled with pt_shell)

The ECO chapter uses `size_cell`, `insert_buffer`, `write_changes`, `fix_eco_timing` and `fix_eco_drc`. Those need the PrimeTime ECO capability enabled in your licence.

## How to use the scripts

Copy the `scripts/` directory next to your flow. In any session:

```tcl
foreach f [glob ./scripts/*.tcl] { source $f }
```

Then call the procs directly. Scripts numbered `01_` and `09_csv_json.tcl` define helpers that later chapters reuse, so source those first if you only pick individual files.

Scripts that start with a configuration block (`02_session_setup.tcl`, `10_dmsa_setup.tcl`) are meant to be copied and edited, not sourced as-is.

## Conventions

- Time values are in the library time unit (usually ns). Nothing in the scripts converts units.
- `slack < 0` is a violation. Slack of `INFINITY` means unconstrained.
- Procs print a table to the console and return the same rows as a Tcl list, so you can post-process without re-running the query.
- Options are given as `-key value` pairs, parsed with `array set`, so any option can be omitted.
- Every script header lists the tool the script targets. Scripts marked "any Tcl 8.x" run under `tclsh` outside PrimeTime.

## Verifying attribute names

PrimeTime attribute names change occasionally between releases. When a script prints an empty column, run:

```tcl
list_attributes -application -class timing_path
list_attributes -application -class pin
list_attributes -application -class clock
```

and adjust the attribute name in the script. Chapter 3 includes `dump_attrs`, which prints every defined attribute for one object so you can find the right name in seconds.

## Recipe index

| # | Recipe | File |
|---|--------|------|
| 1.1 | Collection handling patterns | `01_collection_basics.tcl` |
| 1.2 | Safe attribute access | `01_attr_helpers.tcl` |
| 1.3 | Error handling for batch runs | `01_safe_source.tcl` |
| 1.4 | Keyword argument parsing | `01_args_parser.tcl` |
| 2.1 | Reproducible session bring-up | `02_session_setup.tcl` |
| 2.2 | Environment snapshot | `02_env_report.tcl` |
| 2.3 | check_timing summary table | `02_check_timing_parse.tcl` |
| 2.4 | SDC warnings by command | `02_sdc_echo_filter.tcl` |
| 3.1 | Cell, pin, net queries | `03_find_cells.tcl` |
| 3.2 | Fanin, fanout, cone tracing | `03_fanin_fanout.tcl` |
| 3.3 | Attribute discovery | `03_list_attrs.tcl` |
| 4.1 | One-line-per-path table | `04_path_table.tcl` |
| 4.2 | Slack histogram | `04_slack_histogram.tcl` |
| 4.3 | Clock pair matrix | `04_worst_per_clock_pair.tcl` |
| 4.4 | reg2reg / in2reg classification | `04_path_classify.tcl` |
| 4.5 | Largest stage delays in a path | `04_path_points.tcl` |
| 5.1 | Clock inventory | `05_clock_summary.tcl` |
| 5.2 | Latency statistics and skew | `05_latency_skew.tcl` |
| 5.3 | Generated clock checks | `05_generated_clock_check.tcl` |
| 6.1 | Unconstrained endpoints | `06_unconstrained_endpoints.tcl` |
| 6.2 | Exception audit | `06_exception_audit.tcl` |
| 6.3 | I/O constraint coverage | `06_io_constraint_coverage.tcl` |
| 6.4 | Case analysis and disabled arcs | `06_case_and_disable.tcl` |
| 7.1 | Violator bucketing | `07_bucket_violators.tcl` |
| 7.2 | Cells common to failing paths | `07_common_cells.tcl` |
| 7.3 | DRV table | `07_drv_summary.tcl` |
| 8.1 | ECO sizing candidates | `08_eco_candidates.tcl` |
| 8.2 | Try-and-keep upsizing loop | `08_eco_upsize.tcl` |
| 8.3 | Hold buffer insertion | `08_hold_buffer.tcl` |
| 8.4 | ECO export to ICC2 and Innovus | `08_write_eco.tcl` |
| 8.5 | fix_eco_timing wrapper | `08_fix_eco_wrapper.tcl` |
| 9.1 | CSV and JSON writers | `09_csv_json.tcl` |
| 9.2 | Signoff summary JSON | `09_signoff_summary.tcl` |
| 9.3 | Run-to-run diff | `09_run_diff.tcl` |
| 9.4 | report_timing bundles | `09_custom_report_timing.tcl` |
| 10.1 | DMSA bring-up | `10_dmsa_setup.tcl` |
| 10.2 | Per-scenario collection | `10_scenario_loop.tcl` |
| 10.3 | Merge per-corner CSVs | `10_merge_csv_runs.tcl` |
| 11.1 | Runtime and memory measurement | `11_timing_util.tcl` |
| 11.2 | Slow versus fast patterns | `11_fast_patterns.tcl` |
| 11.3 | Structured logging | `11_logging.tcl` |
