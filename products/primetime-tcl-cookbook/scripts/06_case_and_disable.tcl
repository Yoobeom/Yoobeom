#-----------------------------------------------------------------------
# File    : 06_case_and_disable.tcl
# Author  : youbumkim@gmail.com
# Purpose : Report case analysis and disabled arcs with their origin
# Tool    : PrimeTime (pt_shell)
# Usage   : source 06_case_and_disable.tcl ; case_disable_report rpt_dir
#-----------------------------------------------------------------------

proc case_disable_report {rpt_dir} {
    file mkdir $rpt_dir
    redirect -file $rpt_dir/case_analysis.rpt { report_case_analysis -nosplit }
    redirect -file $rpt_dir/disable_timing.rpt { report_disable_timing -nosplit }

    # Registers whose clock pin is held constant by case analysis:
    # they will never be timed, and that is sometimes not intended.
    set held {}
    foreach_in_collection pin [all_registers -clock_pins] {
        set v [get_attribute -quiet $pin case_value]
        if {$v ne ""} { lappend held [get_object_name $pin] }
    }
    puts "register clock pins with constant case value: [llength $held]"
    set fh [open $rpt_dir/case_held_clock_pins.rpt w]
    foreach h $held { puts $fh $h }
    close $fh

    # Disabled arcs on user cells (not library-defined) come from
    # set_disable_timing in the SDC; count them per cell type.
    array set n {}
    redirect -variable txt { report_disable_timing -nosplit }
    foreach line [split $txt "\n"] {
        if {[regexp {^\s*(\S+)\s+\S+\s+\S+\s+(user|case-analysis|constant|loop-breaking)} $line -> cell why]} {
            if {[info exists n($why)]} { incr n($why) } else { set n($why) 1 }
        }
    }
    foreach why [lsort [array names n]] {
        puts [format "  disabled arcs (%-16s) : %d" $why $n($why)]
    }
}
