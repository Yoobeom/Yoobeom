# Chapter 1. Tcl foundations for PrimeTime

Most PrimeTime scripting bugs are not timing bugs. They are Tcl bugs: a collection treated as a list, an `INFINITY` string fed into `expr`, a `source` that aborted a nine-hour batch at hour eight. This chapter fixes those four classes of bug once, with helpers the rest of the book relies on.

## 1.1 Collections are handles, not lists

`get_cells`, `get_pins`, `get_timing_paths` and friends return a collection. A collection is an opaque handle that looks like `_sel123` when printed. It is not a Tcl list, and the three most common mistakes follow from forgetting that:

- `foreach x $coll` iterates once over the handle string. Use `foreach_in_collection`.
- `llength $coll` returns 1. Use `sizeof_collection`.
- `lindex $coll 0` returns the handle. Use `index_collection $coll 0`.

An empty collection is the empty string, so `if {$coll eq ""}` is the correct emptiness test. Collections are reference counted and freed when the variable goes out of scope, so a proc that builds a large collection and returns it is fine, but a global that holds a million-pin collection for the life of the session costs memory.

{{include:01_collection_basics.tcl}}

`compare_collections -intersect` is the fast membership test. Building a Tcl list of names and calling `lsearch` works for hundreds of objects; it does not work for a million.

## 1.2 Attribute values that are not numbers

`get_attribute` returns strings. Slack can be `INFINITY`. Latency on an ideal clock can be empty. A missing attribute on the wrong object class raises an error unless you pass `-quiet`. Any of these will break an `expr` or a `format %.3f`.

`attr_num` below returns a numeric default for all of those cases, so downstream arithmetic never sees a non-number. `hier_prefix` is the workhorse for every "roll up by block" report in later chapters.

{{include:01_attr_helpers.tcl}}

`string is double -strict` is the right test. Without `-strict`, an empty string passes as a valid double.

## 1.3 Keep the batch running

A signoff batch runs dozens of scripts. One typo in the last one should not lose the session. `safe_source` wraps `source` in `catch`, records the failure, and continues. `run_step` times each block and gives you a choice: stop on the first failure, or record and continue.

{{include:01_safe_source.tcl}}

Use `uplevel #0` so the sourced file sees global scope exactly as it would with a plain `source`. Without it, procs defined in the sourced file would be created inside `safe_source`'s scope and vanish when it returns.

The application variable `sh_continue_on_error` controls whether an error inside a sourced file aborts the whole file. Set it to `true` in batch mode and to `false` when debugging interactively, so the first error stops where you can see it.

## 1.4 Options without positional arguments

Procs with six positional arguments are unreadable at the call site. The pattern used throughout this book is one `args` parameter and an `array set` with defaults:

```tcl
proc my_report {args} {
    array set opt {-group {} -max_paths 100 -out ""}
    array set opt $args
    ...
}
```

The second `array set` overwrites defaults with whatever the caller passed. Any option can be omitted and options can appear in any order. The one weakness is that a misspelled option is silently accepted. `parse_args` adds the check.

{{include:01_args_parser.tcl}}

## 1.5 Three habits that prevent most other bugs

**Quote lists to PrimeTime commands.** `get_cells $name_list` works when `name_list` is a Tcl list, because PrimeTime commands accept a list of patterns. `get_cells "$a $b"` also works but breaks on names containing spaces from escaped hierarchy. Build lists with `lappend`, never with string concatenation.

**Escape brackets in bus names.** A pin named `data_reg[3]/D` must be written `data_reg\[3\]/D` or the bracket is executed as a Tcl command. When names come from `get_object_name` they are already plain strings and can be passed back to `get_pins` without escaping, because `get_pins` receives the string, not the Tcl source.

**Redirect large output to files, never to variables.** `redirect -variable` is fine for `check_timing`. For a 100,000-path `report_timing` it allocates a string of hundreds of megabytes. Use `redirect -file`.
