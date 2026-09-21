#-----------------------------------------------------------------------
# File    : 07_drv_summary.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Max transition / max capacitance violators as a table
# Tool    : PrimeTime (pt_shell)
# Usage   : source 07_drv_summary.tcl ; drv_table -out drv.csv
#-----------------------------------------------------------------------

# Pin-attribute based DRV table. Attribute names differ slightly across
# releases; verify with: list_attributes -application -class pin
proc drv_table {args} {
    array set opt {-out "" -top 50}
    array set opt $args
    set rows {}
    set pins [get_pins -hierarchical -filter "direction == out && is_hierarchical == false"]
    foreach_in_collection p $pins {
        set lim [get_attribute -quiet $p max_transition]
        if {![string is double -strict $lim]} { continue }
        set tr [get_attribute -quiet $p actual_rise_transition_max]
        set tf [get_attribute -quiet $p actual_fall_transition_max]
        set t $tr
        if {[string is double -strict $tf] && (![string is double -strict $t] || $tf > $t)} { set t $tf }
        if {[string is double -strict $t] && $t > $lim} {
            lappend rows [list max_transition [get_object_name $p] $t $lim [expr {$lim - $t}]]
        }
        set clim [get_attribute -quiet $p max_capacitance]
        if {[string is double -strict $clim]} {
            set net [get_nets -quiet -of_objects $p]
            if {$net ne ""} {
                set c [get_attribute -quiet $net total_capacitance_max]
                if {[string is double -strict $c] && $c > $clim} {
                    lappend rows [list max_capacitance [get_object_name $p] $c $clim [expr {$clim - $c}]]
                }
            }
        }
    }
    set rows [lsort -real -index 4 $rows]
    puts [format "%-16s %-55s %9s %9s %9s" CHECK PIN ACTUAL LIMIT SLACK]
    foreach r [lrange $rows 0 [expr {$opt(-top) - 1}]] {
        lassign $r chk pin a l s
        puts [format "%-16s %-55s %9.4f %9.4f %9.4f" $chk $pin $a $l $s]
    }
    puts "total DRV violators: [llength $rows]"
    if {$opt(-out) ne ""} {
        set fh [open $opt(-out) w]
        puts $fh "check,pin,actual,limit,slack"
        foreach r $rows { puts $fh [join $r ","] }
        close $fh
    }
    return $rows
}

# Fallback that does not depend on attribute names: parse report_constraint.
proc drv_count_from_report {} {
    redirect -variable txt {
        report_constraint -all_violators -max_transition -max_capacitance -nosplit
    }
    set n_tran 0
    set n_cap 0
    set section ""
    foreach line [split $txt "\n"] {
        if {[regexp {max_transition} $line]} { set section tran }
        if {[regexp {max_capacitance} $line]} { set section cap }
        if {[regexp {\(VIOLATED\)} $line]} {
            if {$section eq "tran"} { incr n_tran } else { incr n_cap }
        }
    }
    puts "max_transition violators : $n_tran"
    puts "max_capacitance violators: $n_cap"
    return [list $n_tran $n_cap]
}
