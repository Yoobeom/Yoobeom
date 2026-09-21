#-----------------------------------------------------------------------
# File    : 02_sdc_echo_filter.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Find SDC lines that produced warnings while sourcing
# Tool    : PrimeTime (pt_shell)
# Usage   : source 02_sdc_echo_filter.tcl ; sdc_warnings sdc_source.log
#-----------------------------------------------------------------------

# Reads the log written by:  source -echo -verbose top.sdc > sdc_source.log
# Prints each command followed by the warning it triggered, and returns
# the number of commands with warnings.
proc sdc_warnings {logfile {out ""}} {
    set fh [open $logfile r]
    set last_cmd ""
    set n 0
    set lines {}
    while {[gets $fh line] >= 0} {
        if {[regexp {^(set_|create_|group_path|set_case)} $line]} {
            set last_cmd $line
        } elseif {[regexp {^(Warning|Error)} $line]} {
            incr n
            lappend lines "$last_cmd"
            lappend lines "    $line"
        }
    }
    close $fh
    if {$out ne ""} {
        set oh [open $out w]
        puts $oh [join $lines "\n"]
        close $oh
    } else {
        puts [join $lines "\n"]
    }
    puts "$n SDC commands produced warnings"
    return $n
}
