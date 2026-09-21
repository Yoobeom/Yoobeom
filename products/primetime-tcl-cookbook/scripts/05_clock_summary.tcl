#-----------------------------------------------------------------------
# File    : 05_clock_summary.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Clock inventory: period, source, generated master, register count
# Tool    : PrimeTime (pt_shell)
# Usage   : source 05_clock_summary.tcl ; clock_summary
#-----------------------------------------------------------------------

proc clock_summary {} {
    puts [format "%-28s %8s %-10s %-20s %8s  %s" CLOCK PERIOD GEN MASTER NREGS SOURCE]
    set rows {}
    foreach_in_collection c [sort_collection [get_clocks] full_name] {
        set name   [get_object_name $c]
        set period [get_attribute $c period]
        set gen    [get_attribute -quiet $c is_generated]
        set master ""
        if {$gen eq "true"} {
            set master [get_object_name [get_attribute -quiet $c master_clock]]
        }
        set srcs [get_attribute -quiet $c sources]
        set src ""
        if {$srcs ne ""} { set src [get_object_name [index_collection $srcs 0]] }
        set regs [all_registers -clock_pins -clock $c]
        set nregs [sizeof_collection $regs]
        puts [format "%-28s %8s %-10s %-20s %8d  %s" $name $period $gen $master $nregs $src]
        lappend rows [list $name $period $gen $master $nregs $src]
    }
    return $rows
}

# Clocks that drive zero registers: usually a constraint bug.
proc unused_clocks {} {
    set out {}
    foreach_in_collection c [get_clocks] {
        if {[sizeof_collection [all_registers -clock_pins -clock $c]] == 0} {
            lappend out [get_object_name $c]
        }
    }
    puts "clocks driving no registers: $out"
    return $out
}
