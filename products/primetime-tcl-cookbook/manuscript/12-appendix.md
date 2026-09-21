# Appendix A. Command and attribute quick reference

## A.1 Query commands

| Command | Returns | Notes |
|---------|---------|-------|
| `get_cells [-hierarchical] [-filter expr] pattern` | cells | `-hierarchical` searches all levels |
| `get_pins [-of_objects cells] [-leaf]` | pins | `-leaf` skips hierarchical pins |
| `get_nets [-of_objects pins]` | nets | |
| `get_ports`, `all_inputs`, `all_outputs` | ports | |
| `get_clocks`, `all_clocks` | clocks | |
| `all_registers [-clock_pins|-data_pins] [-clock c]` | pins | most reliable register selection |
| `all_fanin -to p -flat [-startpoints_only]` | pins | |
| `all_fanout -from p -flat [-endpoints_only]` | pins | |
| `get_timing_paths [options]` | timing_path | see Chapter 4 |
| `get_path_groups` | path groups | |
| `get_lib_cells lib/cell` | lib_cell | |
| `get_alternative_lib_cells cell` | lib_cell | for ECO sizing |

## A.2 Collection commands

| Command | Purpose |
|---------|---------|
| `foreach_in_collection var coll body` | iterate |
| `sizeof_collection coll` | count |
| `index_collection coll i` | i-th element |
| `add_to_collection a b [-unique]` | union |
| `remove_from_collection a b` | difference |
| `compare_collections -intersect a b` | intersection |
| `filter_collection coll expr` | filter after query |
| `sort_collection [-descending] coll attr` | sort |
| `get_object_name coll` | names as list |

## A.3 Timing path attributes used in this book

| Attribute | Type | Meaning |
|-----------|------|---------|
| `slack` | float or INFINITY | required minus arrival |
| `startpoint`, `endpoint` | object | pin or port |
| `startpoint_clock`, `endpoint_clock` | clock | may be empty |
| `path_group` | path group | |
| `arrival`, `required` | float | at the endpoint |
| `points` | collection of timing_point | ordered along the path |
| `startpoint_clock_latency`, `endpoint_clock_latency` | float | as used for this path |
| `common_path_pessimism` | float | CRPR credit |
| `path_type` | string | `max` or `min` |

## A.4 Application variables that change results

| Variable | Recommended | Effect |
|----------|-------------|--------|
| `timing_remove_clock_reconvergence_pessimism` | true | CRPR |
| `timing_save_pin_arrival_and_slack` | true | pin slack attributes |
| `timing_report_unconstrained_paths` | true | show unconstrained in reports |
| `timing_enable_through_paths` | true | `-through` in exceptions |
| `si_enable_analysis` | per flow | crosstalk (PrimeTime SI) |
| `sh_continue_on_error` | true in batch | do not abort sourced files |

## A.5 ECO commands

| Command | Purpose |
|---------|---------|
| `size_cell cell lib_cell` | change lib cell |
| `insert_buffer pin lib_cell` | add buffer at pin |
| `remove_buffer cell` | remove buffer |
| `write_changes -format icctcl|ptsh|dctcl -output f` | export |
| `fix_eco_timing -type setup|hold -methods {size_cell insert_buffer}` | automatic |
| `fix_eco_drc -type max_transition|max_capacitance` | automatic DRV |

# Appendix B. Equivalents in Cadence Tempus

The scripts target PrimeTime. The same recipes map to Tempus with these substitutions; the logic of each proc is unchanged.

| PrimeTime | Tempus |
|-----------|--------|
| `get_timing_paths` | `report_timing -collection` |
| `get_attribute obj attr` | `get_property obj attr` |
| `foreach_in_collection` | `foreach` over the returned list |
| `sizeof_collection` | `llength` |
| `-slack_lesser_than` | `-max_slack` |
| `points` on a path | `timing_points` |
| `startpoint_clock` | `launching_clock` |
| `endpoint_clock` | `capturing_clock` |
| `all_registers -clock_pins` | `all_registers -clock_pins` |
| `set_app_var` | `set_global` / `setAnalysisMode` |
| `write_changes` | `ecoChangeCell`, `ecoAddRepeater` (direct) |

Tempus returns Tcl lists rather than collections, so the list-versus-collection pitfalls of Chapter 1 do not apply, but a path object is still a handle whose attributes are read with `get_property`.

# Appendix C. Script file list

All scripts are in the `scripts/` directory of this package. Each file is self-contained except where noted.

| File | Depends on |
|------|------------|
| `01_collection_basics.tcl` | none |
| `01_attr_helpers.tcl` | none |
| `01_safe_source.tcl` | none |
| `01_args_parser.tcl` | none |
| `02_session_setup.tcl` | none (edit config block) |
| `02_env_report.tcl` | none |
| `02_check_timing_parse.tcl` | none |
| `02_sdc_echo_filter.tcl` | none |
| `03_find_cells.tcl` | none |
| `03_fanin_fanout.tcl` | none |
| `03_list_attrs.tcl` | none |
| `04_path_table.tcl` | none |
| `04_slack_histogram.tcl` | none |
| `04_worst_per_clock_pair.tcl` | none |
| `04_path_classify.tcl` | none |
| `04_path_points.tcl` | none |
| `05_clock_summary.tcl` | none |
| `05_latency_skew.tcl` | none |
| `05_generated_clock_check.tcl` | none |
| `06_unconstrained_endpoints.tcl` | `timing_save_pin_arrival_and_slack` |
| `06_exception_audit.tcl` | none |
| `06_io_constraint_coverage.tcl` | `timing_save_pin_arrival_and_slack` |
| `06_case_and_disable.tcl` | none |
| `07_bucket_violators.tcl` | none |
| `07_common_cells.tcl` | none |
| `07_drv_summary.tcl` | none |
| `08_eco_candidates.tcl` | ECO capability |
| `08_eco_upsize.tcl` | ECO capability |
| `08_hold_buffer.tcl` | ECO capability, `timing_save_pin_arrival_and_slack` |
| `08_write_eco.tcl` | ECO capability |
| `08_fix_eco_wrapper.tcl` | ECO capability |
| `09_csv_json.tcl` | none |
| `09_signoff_summary.tcl` | `09_csv_json.tcl` |
| `09_run_diff.tcl` | none (tclsh) |
| `09_custom_report_timing.tcl` | none |
| `10_dmsa_setup.tcl` | DMSA (edit corner table) |
| `10_scenario_loop.tcl` | DMSA |
| `10_merge_csv_runs.tcl` | none (tclsh) |
| `11_timing_util.tcl` | none |
| `11_fast_patterns.tcl` | none |
| `11_logging.tcl` | none |
