#-----------------------------------------------------------------------
# File    : 11_fast_patterns.tcl
# Author  : youbumkim@gmail.com
# Purpose : Slow versus fast versions of common queries
# Tool    : PrimeTime (pt_shell)
# Usage   : source 11_fast_patterns.tcl
#-----------------------------------------------------------------------

# SLOW: one get_timing_paths call per endpoint (N timing queries).
proc worst_slack_per_endpoint_slow {endpoints} {
    set out {}
    foreach_in_collection e $endpoints {
        set p [get_timing_paths -to $e -nworst 1 -max_paths 1]
        if {$p ne ""} { lappend out [list [get_object_name $e] [get_attribute $p slack]] }
    }
    return $out
}

# FAST: one query, filter afterwards (one timing query).
proc worst_slack_per_endpoint_fast {endpoints} {
    set out {}
    set paths [get_timing_paths -to $endpoints -nworst 1 -max_paths [sizeof_collection $endpoints] \
                   -slack_lesser_than 1e9]
    foreach_in_collection p $paths {
        lappend out [list [get_object_name [get_attribute $p endpoint]] [get_attribute $p slack]]
    }
    return $out
}

# FASTEST when timing_save_pin_arrival_and_slack is on: no path query.
proc worst_slack_per_endpoint_attr {endpoints} {
    set out {}
    foreach_in_collection e $endpoints {
        lappend out [list [get_object_name $e] [get_attribute -quiet $e max_slack]]
    }
    return $out
}

# SLOW: get_cells inside a loop re-parses the pattern every iteration.
proc mark_dont_touch_slow {names} {
    foreach n $names { set_dont_touch [get_cells $n] }
}

# FAST: build one collection, apply once.
proc mark_dont_touch_fast {names} {
    set_dont_touch [get_cells $names]
}

# SLOW: string concatenation of a large report in a variable.
# FAST: redirect straight to a file.
proc big_report_fast {out} {
    redirect -file $out { report_timing -max_paths 100000 -nworst 1 -path_type end -nosplit }
}

# Filter in the query, not in Tcl: -filter runs in C, foreach runs in Tcl.
proc seq_cells_fast {} {
    return [get_cells -hierarchical -filter "is_sequential == true && is_hierarchical == false"]
}
