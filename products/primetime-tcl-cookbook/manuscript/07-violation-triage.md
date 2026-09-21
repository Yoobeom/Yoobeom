# Chapter 7. Violation triage

Triage is the step between "there are 4,000 violations" and "there are three problems". The scripts here group violators so that each group has one owner and one likely fix.

## 7.1 Bucket by block, clock pair and severity

{{include:07_bucket_violators.tcl}}

The key is `from_block|to_block|launch_clock|capture_clock` at the hierarchy depth you choose. Depth 2 on a typical SoC gives subsystem-level buckets; depth 3 gives block-level. The table is sorted by TNS so the bucket that contributes the most total negative slack is first.

Severity bands are fixed at minus 100 ps and minus 30 ps in the script. Those are reasonable at a 1 GHz clock; scale them for your frequency.

The CSV written with `-out` has one row per violating endpoint and is the input for the run-to-run diff in Chapter 9 and the multi-corner merge in Chapter 10.

## 7.2 Cells that many failing paths share

When 400 failing paths all go through one slow mux, fixing that mux fixes 400 paths. `common_cells_in_violators` counts, for each leaf cell, how many distinct failing paths pass through it.

{{include:07_common_cells.tcl}}

Walking the `points` of 2,000 paths takes a few seconds on a block. On a full chip, restrict `max_paths` or add `-group`. The `seen` array makes sure a cell is counted once per path even if the path enters and exits the cell (input pin and output pin are separate points).

The output is ranked by path count. Cross-check the top entries against `worst`: a cell on many paths but with a worst slack of minus 5 ps is a marginal fix, while a cell on 50 paths at minus 200 ps is a real target.

## 7.3 Design rule violations

Max transition and max capacitance violations often explain setup violations in the same region, and they must be clean for signoff regardless. `drv_table` reads the actual and limit values from pin and net attributes and prints a sortable table.

{{include:07_drv_summary.tcl}}

Attribute names for actual transition (`actual_rise_transition_max`, `actual_fall_transition_max`) and net capacitance (`total_capacitance_max`) are the ones current releases use. `drv_count_from_report` is the release-independent fallback: it counts `(VIOLATED)` markers in `report_constraint -all_violators` output and needs no attribute names at all.

## 7.4 What to do with each bucket

| Bucket pattern | Likely cause | First action |
|----------------|--------------|--------------|
| One clock pair, many blocks, slack near zero | Clock uncertainty or derate change | Compare env report (2.2) with last passing run |
| Async clock pair with violations | Missing `set_clock_groups` or false path | Constraint owner |
| One block, one clock, deep negative | Logic depth | PBA report (9.4), then RTL or synthesis |
| in2reg or reg2out only | I/O delay values | Check 6.3 coverage, then interface spec |
| Many endpoints sharing one cell in 7.2 | Weak driver or high fanout | ECO sizing (8.1) |
| DRV violators in same region | Long net or missing buffer | `fix_eco_drc` (8.5) before setup ECO |
