#-----------------------------------------------------------------------
# File    : 05_latency_skew.tcl
# Author  : youbumkim@gmail.com
# Purpose : Clock latency statistics and skew from path attributes
# Tool    : PrimeTime (pt_shell)
# Usage   : source 05_latency_skew.tcl ; latency_stats CLK
#-----------------------------------------------------------------------

# Min / max / mean capture-clock latency per clock, from the worst path
# to each endpoint. Uses endpoint_clock_latency on timing_path objects.
proc latency_stats {{clk *} {max_paths 50000}} {
    set paths [get_timing_paths -to [all_registers -clock_pins -clock [get_clocks $clk]] \
                   -nworst 1 -max_paths $max_paths -slack_lesser_than 1e9]
    array set mn {}
    array set mx {}
    array set sum {}
    array set n {}
    array set mx_ep {}
    array set mn_ep {}
    foreach_in_collection p $paths {
        set c [get_object_name [get_attribute -quiet $p endpoint_clock]]
        set l [get_attribute -quiet $p endpoint_clock_latency]
        if {$c eq "" || ![string is double -strict $l]} { continue }
        if {![info exists n($c)]} {
            set n($c) 0; set sum($c) 0.0; set mn($c) $l; set mx($c) $l
            set mn_ep($c) ""; set mx_ep($c) ""
        }
        incr n($c)
        set sum($c) [expr {$sum($c) + $l}]
        if {$l < $mn($c)} { set mn($c) $l; set mn_ep($c) [get_object_name [get_attribute $p endpoint]] }
        if {$l > $mx($c)} { set mx($c) $l; set mx_ep($c) [get_object_name [get_attribute $p endpoint]] }
    }
    puts [format "%-24s %6s %8s %8s %8s %8s" CLOCK N MIN MAX MEAN SKEW]
    foreach c [lsort [array names n]] {
        puts [format "%-24s %6d %8.3f %8.3f %8.3f %8.3f" $c $n($c) $mn($c) $mx($c) \
              [expr {$sum($c) / $n($c)}] [expr {$mx($c) - $mn($c)}]]
        puts "    min endpoint: $mn_ep($c)"
        puts "    max endpoint: $mx_ep($c)"
    }
}

# Local skew on failing paths: launch latency minus capture latency.
# Positive value means the launch clock arrives later (hurts setup).
proc skew_on_violators {{top_n 20}} {
    set paths [get_timing_paths -delay_type max -nworst 1 -max_paths 5000 -slack_lesser_than 0]
    set rows {}
    foreach_in_collection p $paths {
        set ll [get_attribute -quiet $p startpoint_clock_latency]
        set cl [get_attribute -quiet $p endpoint_clock_latency]
        set crpr [get_attribute -quiet $p common_path_pessimism]
        if {![string is double -strict $ll] || ![string is double -strict $cl]} { continue }
        if {![string is double -strict $crpr]} { set crpr 0.0 }
        lappend rows [list [expr {$ll - $cl}] [get_attribute $p slack] $ll $cl $crpr \
                      [get_object_name [get_attribute $p endpoint]]]
    }
    set rows [lsort -real -decreasing -index 0 $rows]
    puts [format "%8s %8s %8s %8s %8s  %s" SKEW SLACK LAUNCH CAPT CRPR ENDPOINT]
    foreach r [lrange $rows 0 [expr {$top_n - 1}]] {
        lassign $r sk s ll cl crpr ep
        puts [format "%8.3f %8.3f %8.3f %8.3f %8.3f  %s" $sk $s $ll $cl $crpr $ep]
    }
    return $rows
}
