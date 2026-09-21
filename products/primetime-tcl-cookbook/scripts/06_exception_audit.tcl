#-----------------------------------------------------------------------
# File    : 06_exception_audit.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Audit false paths, multicycle paths and ignored exceptions
# Tool    : PrimeTime (pt_shell)
# Usage   : source 06_exception_audit.tcl ; exception_audit rpt_dir
#-----------------------------------------------------------------------

proc exception_audit {rpt_dir} {
    file mkdir $rpt_dir
    # Exceptions that do not apply to any path: wasted or wrong.
    redirect -file $rpt_dir/exceptions_ignored.rpt {
        report_exceptions -ignored
    }
    # Every exception, with the count of paths it dominates.
    redirect -file $rpt_dir/exceptions_all.rpt {
        report_exceptions
    }
    # Coverage of every check type.
    redirect -file $rpt_dir/coverage.rpt {
        report_analysis_coverage -status_details {untested violated}
    }

    # Count exception commands in each category from the full report.
    set fh [open $rpt_dir/exceptions_all.rpt r]
    array set n {false_path 0 multicycle_path 0 max_delay 0 min_delay 0}
    while {[gets $fh line] >= 0} {
        if {[regexp {^\s*(false_path|multicycle_path|max_delay|min_delay)} $line -> t]} {
            incr n($t)
        }
    }
    close $fh
    puts [format "%-20s %8s" EXCEPTION COUNT]
    foreach t {false_path multicycle_path max_delay min_delay} {
        puts [format "%-20s %8d" $t $n($t)]
    }
    # Ignored count
    set fh [open $rpt_dir/exceptions_ignored.rpt r]
    set ignored 0
    while {[gets $fh line] >= 0} {
        if {[regexp {^\s*(false_path|multicycle_path|max_delay|min_delay)} $line]} { incr ignored }
    }
    close $fh
    puts "ignored exceptions : $ignored   (see $rpt_dir/exceptions_ignored.rpt)"
}

# Multicycle paths whose setup multiplier is set but hold multiplier is
# missing: the classic -setup 2 without -hold 1 mistake.
proc mcp_hold_check {} {
    redirect -variable txt { report_exceptions -nosplit }
    set setup_only 0
    foreach line [split $txt "\n"] {
        if {[regexp {multicycle_path} $line] && [regexp {setup} $line] && ![regexp {hold} $line]} {
            incr setup_only
            puts "  $line"
        }
    }
    puts "multicycle setup-only entries (verify hold): $setup_only"
    return $setup_only
}
