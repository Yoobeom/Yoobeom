# Chapter 6. Constraint audit

An SDC that loads without errors is not a correct SDC. The tests in this chapter measure what the constraints cover and what they leave out. Run them on every SDC delivery, before any timing number is discussed.

## 6.1 Endpoints with no timing check

An endpoint with `max_slack` of `INFINITY` is not timed. `report_analysis_coverage` counts them; this script names them and rolls them up by block, so a list of 8,000 pins becomes "u_dma has 7,900 of them", which points at a missing clock rather than 7,900 individual problems.

{{include:06_unconstrained_endpoints.tcl}}

The proc requires `timing_save_pin_arrival_and_slack true` set before `update_timing`, as described in Chapter 2. Without it, `max_slack` is empty on every pin and the script reports every endpoint as unconstrained.

## 6.2 Exceptions that apply to nothing

`report_exceptions -ignored` lists `set_false_path`, `set_multicycle_path`, `set_max_delay` and `set_min_delay` commands that matched no path. Each one is either a typo in an object name, a hierarchy that was renamed, or an exception that was never needed. All three are worth knowing about.

{{include:06_exception_audit.tcl}}

`mcp_hold_check` looks for the most common multicycle mistake: `set_multicycle_path -setup 2` without a matching `-hold 1`. PrimeTime moves the hold check to the same edge as the setup check, one cycle later, and the path then needs a full cycle of hold margin. The proc lists multicycle entries that mention setup but not hold; review each one.

## 6.3 I/O constraint coverage

{{include:06_io_constraint_coverage.tcl}}

The four lists returned are:

1. Input ports with no path timed from them (no `set_input_delay`, or the delay refers to a clock that does not exist).
2. Input ports with no `set_driving_cell` or `set_input_transition`, so the timer uses a zero transition and the first stage is optimistic.
3. Output ports with no path timed to them.
4. Output ports with no `set_load`, so the driver sees no capacitance and is optimistic.

Clock source ports are excluded from the delay checks. The port attribute names for driving cell and input transition vary between releases; if both come back empty on a port you know is constrained, check `list_attributes -application -class port`.

## 6.4 Case analysis and disabled arcs

`set_case_analysis` is how a mode is selected: scan enable low, test mode off, a clock mux select. A wrong case value silently removes logic from analysis. The script writes the case and disable reports and adds a specific check: register clock pins held constant by case analysis, which means those registers are not timed at all.

{{include:06_case_and_disable.tcl}}

The disabled-arc counts by origin separate library-defined disables (normal) from user `set_disable_timing` (review each) and from loop breaking (the timer broke a combinational loop; the choice of arc is arbitrary and may hide a real path).
