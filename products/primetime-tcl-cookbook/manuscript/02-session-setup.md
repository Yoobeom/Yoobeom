# Chapter 2. Session setup and sanity checks

A signoff session must be reproducible: same netlist, same libraries, same variables, same result. The four scripts in this chapter make the session a data file rather than a memory of what was typed last time.

## 2.1 One configuration block per run

Everything that changes between blocks, corners and modes lives in the `cfg` array at the top of the script. Everything below the array is the same for every run. When a result cannot be reproduced, diffing two configuration blocks is a 30-second job; diffing two shell histories is not.

{{include:02_session_setup.tcl}}

Three variables in step 2 deserve attention:

- `timing_save_pin_arrival_and_slack true` makes `max_slack`, `min_slack` and arrival attributes available on pins after `update_timing`. Chapters 6 and 11 depend on it. Set it before the first `update_timing`.
- `timing_report_unconstrained_paths true` lets `report_timing` show paths that have no constraint instead of hiding them. It is the fastest way to notice a missing clock.
- `timing_remove_clock_reconvergence_pessimism true` enables CRPR. Leaving it off makes hold analysis pessimistic on shared clock tree segments.

The `source -echo -verbose` into a log file in step 5 is the input for recipe 2.4.

`save_session` at the end writes a restartable image. ECO iterations that start from `restore_session` skip netlist and parasitic reading, which is most of the bring-up time on a large block.

## 2.2 Record the environment

When two engineers get different numbers from "the same" run, the difference is almost always a variable, a library version, or a derate. `write_env_report` writes all three to one file that can be attached to a review.

{{include:02_env_report.tcl}}

The variable list is deliberately explicit. `report_app_var` prints hundreds of variables; a reviewer needs the fifteen that change timing results.

## 2.3 Turn check_timing into a pass/fail gate

`check_timing -verbose` output is long and free-form. The categories that matter for a gate are `no_clock` and `unconstrained_endpoints`: either one means a portion of the design is not being timed. `check_timing_summary` counts findings per category and returns non-zero when a fatal category has any.

{{include:02_check_timing_parse.tcl}}

The regular expression matches the `Checking 'category'` header lines that PrimeTime prints in verbose mode. If a release changes that format, adjust the pattern; the rest of the proc does not depend on it.

## 2.4 Find which SDC line produced which warning

An SDC of 20,000 lines typically produces a few hundred warnings when sourced. The warnings are useful only if you know which command caused each one. Sourcing with `-echo -verbose` prints each command followed by its warnings; `sdc_warnings` pairs them.

{{include:02_sdc_echo_filter.tcl}}

The most valuable finding is usually a `set_false_path` or `set_multicycle_path` whose `-from` or `-to` matched nothing. The exception is silently dropped and the path is timed as a normal single-cycle path. Recipe 6.2 catches the same problem from the other side with `report_exceptions -ignored`.
