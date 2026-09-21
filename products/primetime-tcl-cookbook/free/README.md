# Free sample: 4 PrimeTime Tcl scripts

Four of the 41 scripts from the PrimeTime Tcl Cookbook, unchanged. Source them in pt_shell after `update_timing`.

| File | What it does |
|------|--------------|
| `01_collection_basics.tcl` | Collection patterns: iterate, combine, filter, membership test |
| `01_attr_helpers.tcl` | INFINITY-safe attribute access, hierarchy prefix, formatting |
| `01_safe_source.tcl` | Batch error handling: keep a 9-hour run going past a typo |
| `04_worst_per_clock_pair.tcl` | Worst slack, violator count and path count for every launch/capture clock pair, one query |

```tcl
source 04_worst_per_clock_pair.tcl
clock_pair_matrix
```

The full package (56-page guide, 41 scripts: session setup, SDC audit, violator bucketing, ECO sizing loop, hold buffering with setup guard, JSON export, DMSA) is here: GUMROAD_URL
