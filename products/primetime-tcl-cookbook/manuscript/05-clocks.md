# Chapter 5. Clock analysis

Half of all "timing violations" found in the first pass of a new block are clock definition problems: a generated clock with the wrong divide ratio, a master clock that never reaches its generated clock's source pin, a clock defined on a port that also has an input delay. These scripts find them before anyone spends time on the data path.

## 5.1 Clock inventory

{{include:05_clock_summary.tcl}}

The register count column is the important one. A clock with zero registers is either a virtual clock (fine, if intended for I/O constraints) or a clock definition on the wrong pin. A generated clock with far fewer registers than its master often has the wrong `-source`.

`all_registers -clock -clock_pins` returns the clock pins of registers clocked by that clock, which is the only reliable way to count them. Tracing the clock network with `all_fanout` would include ICGs and clock buffers.

## 5.2 Latency and skew

`report_clock_timing -type skew` exists, but its output is not easy to post-process and it does not tell you which endpoint has the extreme latency. The path attributes `startpoint_clock_latency` and `endpoint_clock_latency` are available on every path object and give the latency the timer used for that specific path.

{{include:05_latency_skew.tcl}}

`latency_stats` reports the spread of capture latency per clock with the endpoints at each extreme. A spread larger than a clock buffer stage on a balanced tree points at an unbalanced branch, a hold-fix insertion on a clock line, or a wrong `set_clock_latency` override.

`skew_on_violators` shows how much of each failing path's slack is explained by skew. A path with skew of 150 ps and slack of minus 120 ps is a clock tree problem; the data path is fine.

`common_path_pessimism` is the CRPR credit the timer applied. If it is zero on a path where launch and capture share most of the tree, `timing_remove_clock_reconvergence_pessimism` is probably off.

## 5.3 Generated clock sanity

{{include:05_generated_clock_check.tcl}}

The check reads the `clocks` attribute on the generated clock's source pin. If the master clock is not in that list, the master does not propagate to the source, and PrimeTime will report the generated clock with zero latency or no timing at all. The usual cause is a `set_case_analysis` on a mux select that blocks the master, or a `set_disable_timing` on the divider.

Multiple clocks on one source pin are listed as notes rather than issues; they are legitimate when the pin carries a mux of two clocks that are timed in the same mode, but each such case should be intentional.

## 5.4 Constraint commands this chapter assumes

| Command | What the scripts expect |
|---------|-------------------------|
| `create_clock -period P -name N [get_ports ...]` | `sources` attribute holds the port |
| `create_generated_clock -source S -divide_by N -master_clock M` | `master_clock`, `is_generated` set |
| `set_propagated_clock [all_clocks]` | latency attributes are real, not ideal |
| `set_clock_groups -asynchronous` | pair matrix rows for those pairs are absent |
| `set_clock_uncertainty` | included in `required`, not in latency |
