#-----------------------------------------------------------------------
# File    : 01_safe_source.tcl
# Author  : youbumkim@gmail.com
# Purpose : Error handling wrappers for long batch runs
# Tool    : PrimeTime (pt_shell)
# Usage   : source 01_safe_source.tcl ; safe_source my_flow.tcl
#-----------------------------------------------------------------------

# Sources a file and keeps going on error, recording the failure.
# The global list ::flow_errors collects {file message} pairs.
set ::flow_errors {}

proc safe_source {file} {
    if {![file exists $file]} {
        lappend ::flow_errors [list $file "file not found"]
        puts "Error: $file not found"
        return 0
    }
    if {[catch {uplevel #0 [list source $file]} err]} {
        lappend ::flow_errors [list $file $err]
        puts "Error: sourcing $file failed: $err"
        return 0
    }
    return 1
}

# Runs a command block, reports duration, and stops the flow if
# stop_on_error is 1.
proc run_step {name body {stop_on_error 1}} {
    set t0 [clock seconds]
    puts "==== STEP $name start"
    set rc [catch {uplevel 1 $body} err]
    set dt [expr {[clock seconds] - $t0}]
    if {$rc} {
        puts "==== STEP $name FAILED after ${dt}s : $err"
        if {$stop_on_error} {
            error "flow stopped at step $name"
        }
        return 0
    }
    puts "==== STEP $name done in ${dt}s"
    return 1
}

# Prints and returns the collected error list.
proc report_flow_errors {} {
    if {[llength $::flow_errors] == 0} {
        puts "No flow errors recorded."
        return {}
    }
    puts "Flow errors:"
    foreach e $::flow_errors {
        puts "  [lindex $e 0] : [lindex $e 1]"
    }
    return $::flow_errors
}
