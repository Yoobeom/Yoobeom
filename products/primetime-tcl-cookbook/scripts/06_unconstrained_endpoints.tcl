#-----------------------------------------------------------------------
# File    : 06_unconstrained_endpoints.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : List register data pins and output ports with no timing check
# Tool    : PrimeTime (pt_shell)
# Usage   : source 06_unconstrained_endpoints.tcl ; unconstrained_endpoints out.rpt
#-----------------------------------------------------------------------

# Requires: set_app_var timing_save_pin_arrival_and_slack true  (before update_timing)
# A pin whose max_slack is INFINITY has no setup check reaching it.
proc unconstrained_endpoints {{out ""}} {
    set eps [add_to_collection [all_registers -data_pins] [all_outputs]]
    set rows {}
    foreach_in_collection e $eps {
        set s [get_attribute -quiet $e max_slack]
        if {$s eq "" || $s eq "INFINITY"} {
            set cls [get_attribute $e object_class]
            set ref ""
            if {$cls eq "pin"} {
                set ref [get_attribute -quiet [get_cells -of_objects $e] ref_name]
            }
            lappend rows [list [get_object_name $e] $cls $ref]
        }
    }
    set rows [lsort -index 0 $rows]
    if {$out ne ""} {
        set fh [open $out w]
        foreach r $rows { puts $fh [join $r "\t"] }
        close $fh
    }
    puts "unconstrained endpoints: [llength $rows] of [sizeof_collection $eps]"
    return $rows
}

# Roll the list up by hierarchy so a 10,000-line list becomes 20 lines.
proc unconstrained_by_block {{depth 2}} {
    array set n {}
    foreach r [unconstrained_endpoints] {
        set name [lindex $r 0]
        set parts [split $name "/"]
        set key [join [lrange $parts 0 [expr {$depth - 1}]] "/"]
        if {[info exists n($key)]} { incr n($key) } else { set n($key) 1 }
    }
    set rows {}
    foreach k [array names n] { lappend rows [list $k $n($k)] }
    set rows [lsort -integer -decreasing -index 1 $rows]
    puts [format "%-50s %8s" BLOCK UNCONSTRAINED]
    foreach r $rows { puts [format "%-50s %8d" [lindex $r 0] [lindex $r 1]] }
    return $rows
}
