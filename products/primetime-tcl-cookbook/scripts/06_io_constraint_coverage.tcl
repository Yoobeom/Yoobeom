#-----------------------------------------------------------------------
# File    : 06_io_constraint_coverage.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Ports missing input/output delay, drive, or load
# Tool    : PrimeTime (pt_shell)
# Usage   : source 06_io_constraint_coverage.tcl ; io_coverage
#-----------------------------------------------------------------------

proc io_coverage {} {
    set no_in_delay  {}
    set no_out_delay {}
    set no_drive     {}
    set no_load      {}
    set clocks_src   {}
    # ports that are clock sources are excluded from delay checks
    foreach_in_collection c [get_clocks] {
        foreach_in_collection s [get_attribute -quiet $c sources] {
            if {[get_attribute $s object_class] eq "port"} {
                lappend clocks_src [get_object_name $s]
            }
        }
    }
    foreach_in_collection p [all_inputs] {
        set n [get_object_name $p]
        if {[lsearch -exact $clocks_src $n] >= 0} { continue }
        # max_slack INFINITY on an input means nothing launches from it
        set s [get_attribute -quiet $p max_slack]
        if {$s eq "" || $s eq "INFINITY"} { lappend no_in_delay $n }
        set dr [get_attribute -quiet $p driving_cell_rise_max]
        set tr [get_attribute -quiet $p input_transition_max_rise]
        if {$dr eq "" && $tr eq ""} { lappend no_drive $n }
    }
    foreach_in_collection p [all_outputs] {
        set n [get_object_name $p]
        set s [get_attribute -quiet $p max_slack]
        if {$s eq "" || $s eq "INFINITY"} { lappend no_out_delay $n }
        set ld [get_attribute -quiet $p pin_capacitance_max]
        if {$ld eq "" || $ld == 0} { lappend no_load $n }
    }
    puts "inputs  without arrival/delay : [llength $no_in_delay]"
    puts "inputs  without drive/transition: [llength $no_drive]"
    puts "outputs without required/delay: [llength $no_out_delay]"
    puts "outputs without load          : [llength $no_load]"
    return [list $no_in_delay $no_drive $no_out_delay $no_load]
}
