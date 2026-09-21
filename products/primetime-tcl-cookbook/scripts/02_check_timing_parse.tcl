#-----------------------------------------------------------------------
# File    : 02_check_timing_parse.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Turn check_timing output into a pass/fail summary table
# Tool    : PrimeTime (pt_shell)
# Usage   : source 02_check_timing_parse.tcl ; check_timing_summary
#-----------------------------------------------------------------------

# Returns a list of {check count} pairs. Prints a compact table.
# Any non-zero count in the "fatal" list makes the proc return 1.
proc check_timing_summary {{fatal {no_clock unconstrained_endpoints}}} {
    redirect -variable txt { check_timing -verbose }
    array set count {}
    set current ""
    foreach line [split $txt "\n"] {
        # Section headers look like:  "Information: Checking 'no_clock'."
        if {[regexp {Checking '([a-z_]+)'} $line -> chk]} {
            set current $chk
            if {![info exists count($chk)]} { set count($chk) 0 }
            continue
        }
        # Body lines under a section that name an object are findings.
        if {$current ne "" && [regexp {^\s+\S} $line] && ![regexp {Warning|Information} $line]} {
            incr count($current)
        }
    }
    puts [format "%-32s %8s" CHECK COUNT]
    set rc 0
    foreach chk [lsort [array names count]] {
        set flag ""
        if {$count($chk) > 0 && [lsearch -exact $fatal $chk] >= 0} {
            set flag "  <-- FATAL"
            set rc 1
        }
        puts [format "%-32s %8d%s" $chk $count($chk) $flag]
    }
    return $rc
}
