#-----------------------------------------------------------------------
# File    : 03_fanin_fanout.tcl
# Author  : youbumkim@gmail.com
# Purpose : Cone tracing helpers built on all_fanin / all_fanout
# Tool    : PrimeTime (pt_shell)
# Usage   : source 03_fanin_fanout.tcl
#-----------------------------------------------------------------------

# Registers that launch into a given endpoint pin.
proc launch_regs_of {endpoint_pin} {
    return [all_fanin -to $endpoint_pin -flat -startpoints_only]
}

# Endpoints reachable from a register output pin.
proc capture_pins_of {start_pin} {
    return [all_fanout -from $start_pin -flat -endpoints_only]
}

# Logic depth of a cone: number of leaf cells between start and end.
proc cone_cell_count {from_pin to_pin} {
    set fo [all_fanout -from $from_pin -flat]
    set fi [all_fanin  -to   $to_pin   -flat]
    set cone_pins [compare_collections -intersect $fo $fi]
    if {$cone_pins eq ""} { return 0 }
    set cells [get_cells -of_objects $cone_pins -filter "is_hierarchical == false"]
    return [sizeof_collection $cells]
}

# Nets with fanout above a threshold, sorted, with driver pin.
proc high_fanout_nets {{limit 32} {top_n 50}} {
    set rows {}
    foreach_in_collection n [get_nets -hierarchical] {
        set loads [get_pins -quiet -of_objects $n -leaf -filter "direction == in"]
        set fo [sizeof_collection $loads]
        if {$fo >= $limit} {
            set drv [get_pins -quiet -of_objects $n -leaf -filter "direction == out"]
            set drv_name ""
            if {$drv ne ""} { set drv_name [get_object_name [index_collection $drv 0]] }
            lappend rows [list [get_object_name $n] $fo $drv_name]
        }
    }
    set rows [lsort -integer -decreasing -index 1 $rows]
    puts [format "%-60s %6s  %s" NET FANOUT DRIVER]
    foreach r [lrange $rows 0 [expr {$top_n - 1}]] {
        puts [format "%-60s %6d  %s" [lindex $r 0] [lindex $r 1] [lindex $r 2]]
    }
    return $rows
}

# Does pin A reach pin B through combinational logic?
proc reaches {from_pin to_pin} {
    set fo [all_fanout -from $from_pin -flat -endpoints_only]
    return [expr {[sizeof_collection [compare_collections -intersect $fo $to_pin]] > 0}]
}
