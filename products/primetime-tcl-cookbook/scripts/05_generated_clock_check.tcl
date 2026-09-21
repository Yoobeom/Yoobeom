#-----------------------------------------------------------------------
# File    : 05_generated_clock_check.tcl
# Author  : youbumkim@gmail.com
# Purpose : Sanity checks on generated clocks and clock sources
# Tool    : PrimeTime (pt_shell)
# Usage   : source 05_generated_clock_check.tcl ; generated_clock_check
#-----------------------------------------------------------------------

# Flags:
#  - generated clock whose master drives no registers itself
#  - generated clock whose source pin has no master clock on it
#  - two clocks defined on the same source pin (usually intended, but list)
proc generated_clock_check {} {
    array set by_src {}
    set issues 0
    foreach_in_collection c [get_clocks] {
        set name [get_object_name $c]
        set srcs [get_attribute -quiet $c sources]
        foreach_in_collection s $srcs {
            set sn [get_object_name $s]
            lappend by_src($sn) $name
        }
        if {[get_attribute -quiet $c is_generated] ne "true"} { continue }
        set master [get_attribute -quiet $c master_clock]
        if {$master eq ""} {
            puts "ISSUE  $name : generated clock has no master"
            incr issues
            continue
        }
        set mname [get_object_name $master]
        if {$srcs ne ""} {
            set src0 [index_collection $srcs 0]
            set clks_on_src [get_attribute -quiet $src0 clocks]
            set found 0
            foreach_in_collection k $clks_on_src {
                if {[get_object_name $k] eq $mname} { set found 1 }
            }
            if {!$found} {
                puts "ISSUE  $name : master $mname does not reach source [get_object_name $src0]"
                incr issues
            }
        }
    }
    foreach sn [array names by_src] {
        if {[llength $by_src($sn)] > 1} {
            puts "NOTE   $sn : multiple clocks defined here: $by_src($sn)"
        }
    }
    puts "generated clock issues: $issues"
    return $issues
}
