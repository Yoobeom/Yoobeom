#-----------------------------------------------------------------------
# File    : 11_logging.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Structured run log with levels, written to file and stdout
# Tool    : PrimeTime (pt_shell) or any Tcl 8.x
# Usage   : source 11_logging.tcl ; log_open run.log ; log INFO "started"
#-----------------------------------------------------------------------

set ::log_fh ""
set ::log_level 1     ;# 0=DEBUG 1=INFO 2=WARN 3=ERROR

proc log_open {file} {
    set ::log_fh [open $file a]
    log INFO "log opened: $file"
}

proc log_close {} {
    if {$::log_fh ne ""} { close $::log_fh; set ::log_fh "" }
}

proc log {level msg} {
    array set lv {DEBUG 0 INFO 1 WARN 2 ERROR 3}
    if {$lv($level) < $::log_level} { return }
    set line [format "%s %-5s %s" [clock format [clock seconds] -format "%H:%M:%S"] $level $msg]
    puts $line
    if {$::log_fh ne ""} { puts $::log_fh $line; flush $::log_fh }
}

# Run a body and log its start, end, duration and any error.
proc log_step {name body} {
    log INFO "start $name"
    set t0 [clock seconds]
    if {[catch {uplevel 1 $body} err]} {
        log ERROR "$name failed: $err"
        return -code error $err
    }
    log INFO "done  $name ([expr {[clock seconds] - $t0}]s)"
}
