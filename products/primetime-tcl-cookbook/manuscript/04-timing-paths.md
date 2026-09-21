# Chapter 4. Timing path analysis

`report_timing` is for reading one path. `get_timing_paths` is for reading ten thousand. The difference is that the second returns objects with attributes, and everything in this chapter is built on those attributes.

## 4.1 The options that control what you get

```tcl
get_timing_paths -delay_type max \
    -nworst 1 -max_paths 1000 \
    -slack_lesser_than 0 \
    -group CLK_A
```

- `-delay_type max` is setup, `min` is hold.
- `-nworst N` is the number of paths per endpoint. For triage use 1: you want the worst path to each endpoint, not ten variants of the same endpoint.
- `-max_paths N` is the total. It defaults to 1, which is why a bare `get_timing_paths` returns a single path.
- `-slack_lesser_than 0` limits the query to violators. Combine with `-slack_greater_than` to select a slack band.
- `-slack_lesser_than 1e9` is the idiom for "all endpoints including positive slack", used by the histogram recipe. Without a `-slack_lesser_than`, PrimeTime still returns only paths up to `-max_paths`, sorted worst first, but the default threshold in some releases cuts positive-slack paths; the explicit large value removes that dependence.
- `-pba_mode path` or `exhaustive` applies path-based analysis. It is slower and should be used on a short list after graph-based triage.

## 4.2 One line per path

{{include:04_path_table.tcl}}

`startpoint` and `endpoint` are objects, so `get_object_name` is required. `startpoint_clock` can be empty on a path launched from an unclocked input, hence the `-quiet`.

The `eval format [list $fmt] $r` construction applies a format string to a row stored as a list. It is the same pattern used for every table in the book.

## 4.3 Slack histogram

A histogram shows whether a block has ten paths at minus 300 ps or three thousand paths at minus 20 ps. Those need different fixes: the first is a logic restructure, the second is a clock or derate problem.

{{include:04_slack_histogram.tcl}}

Bins are in slack units. `-bin 0.020` with ns units gives 20 ps bins. Endpoints with slack below `-min` are collected into one "below" row so a single deep outlier does not stretch the chart.

## 4.4 Worst slack per launch/capture clock pair

A clock pair matrix is the first thing to look at when a design has many clocks. A negative slack on a pair like `CLK_A -> CLK_B` where no synchronous relationship exists means a missing false path or clock group, not a timing problem.

{{include:04_worst_per_clock_pair.tcl}}

`startpoint_clock` and `endpoint_clock` are attributes of the path, not of the pins, so they reflect the clock the timer actually used for that path, including generated clocks and case-analysis-selected clocks.

## 4.5 reg2reg, in2reg, reg2out, in2out

I/O paths often fail because the I/O constraint is wrong, not because the logic is slow. Separating them from register-to-register paths lets you hand each list to the right person.

{{include:04_path_classify.tcl}}

The macro bucket relies on `is_black_box`, which is true for cells whose timing comes from a `.lib` with no internal netlist (memories, IP hard macros). Adjust to `ref_name =~` patterns if your library marks macros differently.

## 4.6 Where the delay is inside a path

For one path, the question is which stage is slow. `biggest_stages` walks the `points` collection, computes the increment between consecutive points, and prints the largest.

{{include:04_path_points.tcl}}

`cell_net_split` uses the direction of the pin at each point to attribute an increment to cell delay (increment ending at an output pin) or net delay (increment ending at an input pin). It is an approximation that ignores clock network points, which is acceptable for data path review.

A path where net delay dominates is a placement or routing problem; a path where one cell contributes 30% is a sizing problem. Chapter 8 uses the same walk to pick ECO candidates.
