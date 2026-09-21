# Chapter 10. Multi-corner, multi-mode

Signoff is never one corner. There are two ways to run many: distributed multi-scenario analysis (DMSA), where one master pt_shell coordinates slave processes and merges results, or independent single-scenario runs joined afterwards by script. Both are covered; the second needs no extra licence features and is often what a small team actually does.

## 10.1 DMSA bring-up from a corner table

{{include:10_dmsa_setup.tcl}}

The corner table is the only thing to edit. The script writes one scenario file per mode/corner combination, creates the scenarios, and runs `update_timing` in every slave with one `remote_execute`. Reports run at the master level merge across scenarios: the merged end-only report shows each endpoint at its worst scenario.

`set_host_options -num_processes` is the number of slaves. Each slave holds a full copy of the design; size the count by memory, not by cores.

## 10.2 Collect per-scenario data

`remote_execute` sends a Tcl block to every slave in the current session. Slaves cannot return values directly, so the pattern is: each slave writes a small file named after `current_scenario`, and the master reads them all.

{{include:10_scenario_loop.tcl}}

`collect_wns_per_scenario` gives one line per scenario, which answers the first question of any review: is one corner much worse than the rest. `worst_scenario_for` answers the question that comes before any ECO: in which scenario must this endpoint be fixed, and which scenarios must be checked afterwards.

Both procs bake master-side values into the block before sending it (`string map` in the first, a double-quoted string in the second) because the block is evaluated in the slave, where the master's variables do not exist. A brace-quoted block containing `$dir` would fail in every slave with an undefined variable.

## 10.3 Merge independent runs

Without DMSA, each corner runs in its own pt_shell and writes its own violator CSV (recipe 7.1). `merge_runs` joins them into one worst-per-endpoint table with the corner that produced the worst value and the number of corners in which the endpoint fails.

{{include:10_merge_csv_runs.tcl}}

The corner name is taken from the directory containing each CSV, so a layout of `rpt/<mode>_<corner>/violators.csv` works without any extra argument. The script runs under `tclsh`.

An endpoint failing in one corner only is usually a corner-specific issue (a hold violation in the fast corner, a setup violation with cworst parasitics). An endpoint failing in every corner is a logic depth problem.
