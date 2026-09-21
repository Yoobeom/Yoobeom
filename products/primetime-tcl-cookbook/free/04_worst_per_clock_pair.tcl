#-----------------------------------------------------------------------
# File    : 04_worst_per_clock_pair.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Worst slack and violator count for every launch/capture pair
# Tool    : PrimeTime (pt_shell)
# Usage   : source 04_worst_per_clock_pair.tcl ; clock_pair_matrix
#-----------------------------------------------------------------------

proc clock_pair_matrix {{delay_type max} {max_paths 50000}} {
    set paths [get_timing_paths -delay_type $delay_type -nworst 1 \
                   -max_paths $max_paths -slack_lesser_than 1e9]
    array set worst {}
    array set nviol {}
    array set npath {}
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        if {![string is double -strict $s]} { continue }
        set l [get_object_name [get_attribute -quiet $p startpoint_clock]]
        set c [get_object_name [get_attribute -quiet $p endpoint_clock]]
        if {$l eq ""} { set l "(none)" }
        if {$c eq ""} { set c "(none)" }
        set key "$l,$c"
        if {![info exists worst($key)] || $s < $worst($key)} { set worst($key) $s }
        if {![info exists npath($key)]} { set npath($key) 0; set nviol($key) 0 }
        incr npath($key)
        if {$s < 0} { incr nviol($key) }
    }
    set rows {}
    foreach key [array names worst] {
        lappend rows [list $key $worst($key) $nviol($key) $npath($key)]
    }
    set rows [lsort -real -index 1 $rows]
    puts [format "%-30s %-30s %9s %8s %8s" LAUNCH CAPTURE WORST NVIOL NPATH]
    foreach r $rows {
        lassign $r key w v n
        lassign [split $key ","] l c
        puts [format "%-30s %-30s %9.3f %8d %8d" $l $c $w $v $n]
    }
    return $rows
}
