# Chapter 3. Querying the design

Every analysis script starts by selecting objects. Selecting them with `-filter` inside the query runs in the tool's C code. Selecting them by looping in Tcl and testing attributes runs ten to a hundred times slower. This chapter is about pushing as much of the selection as possible into the query.

## 3.1 Cells, pins and nets by type and name

{{include:03_find_cells.tcl}}

The `-filter` expression language supports `==`, `!=`, `=~` (glob match), `!~`, `>`, `<`, `&&`, `||`. Attribute names inside the filter are unquoted. A common mistake is writing `is_sequential == "true"` with quotes; PrimeTime accepts both but the unquoted form is canonical.

`cell_histogram` is the quickest way to answer "what is this block made of" before a review. Sorted by count, the first ten lines usually cover 80% of the area.

`area_under` uses `-quiet` on the area attribute because hierarchical cells and some macros have no area in the timing library.

## 3.2 Cone tracing

`all_fanin` and `all_fanout` are the primitives. The three options that matter:

- `-flat` crosses hierarchy. Without it the trace stops at hierarchical pins.
- `-startpoints_only` / `-endpoints_only` returns timing startpoints or endpoints instead of every pin in the cone.
- `-levels N` limits depth when the full cone is too large.

{{include:03_fanin_fanout.tcl}}

`high_fanout_nets` loops over every net, which is slow on a full chip. Run it on a block, or narrow `get_nets` with a pattern first. The `-leaf` option on `get_pins` skips hierarchical pins so the count is the number of real loads.

`reaches` is expensive when the fanout cone from `from_pin` is large, because it builds the whole cone before intersecting. When you only need to know whether a path exists, `get_timing_paths -from $a -to $b -max_paths 1` is usually cheaper because the timer can stop at the first path.

## 3.3 Finding the attribute you need

`list_attributes -application -class <class>` prints the attribute table for a class. `dump_attrs` goes one step further and prints the value of every attribute on one object, so you can see what the attribute actually contains for your design.

{{include:03_list_attrs.tcl}}

Attributes that return collections print as `_sel` handles; the proc replaces those with the collection size. Run `dump_attrs [get_timing_paths -max_paths 1]` once on any design and keep the output; it is the fastest reference for Chapter 4.

## 3.4 Object classes you will meet

| Class | Typical source | Attributes used in this book |
|-------|----------------|------------------------------|
| cell | `get_cells` | `ref_name`, `full_name`, `is_hierarchical`, `is_sequential`, `is_integrated_clock_gating_cell`, `area`, `dont_touch`, `is_black_box` |
| pin | `get_pins`, `all_registers -clock_pins` | `direction`, `max_slack`, `min_slack`, `max_transition`, `actual_rise_transition_max`, `case_value`, `clocks` |
| port | `get_ports`, `all_inputs` | `max_slack`, `pin_capacitance_max`, `driving_cell_rise_max`, `input_transition_max_rise` |
| net | `get_nets` | `total_capacitance_max` |
| clock | `get_clocks` | `period`, `sources`, `is_generated`, `master_clock` |
| timing_path | `get_timing_paths` | `slack`, `startpoint`, `endpoint`, `startpoint_clock`, `endpoint_clock`, `path_group`, `arrival`, `required`, `points`, `startpoint_clock_latency`, `endpoint_clock_latency`, `common_path_pessimism` |
| timing_point | `points` of a path | `object`, `arrival`, `transition` |
| lib_cell | `get_lib_cells`, `get_alternative_lib_cells` | `base_name`, `area` |

`object_class` is defined on every object and is how the classification scripts tell a port from a pin.
