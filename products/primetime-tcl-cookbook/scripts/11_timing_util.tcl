#-----------------------------------------------------------------------
# File    : 11_timing_util.tcl
# Author  : youbumkim@gmail.com
# Purpose : Measure runtime and memory of any command block
# Tool    : PrimeTime (pt_shell)
# Usage   : source 11_timing_util.tcl ; timeit "worst paths" { get_timing_paths -max_paths 10000 }
#-----------------------------------------------------------------------

proc mem_mb {} {
    # sh_memory_usage is not available in every release; fall back to /proc
    if {![catch {set m [get_app_var sh_memory_usage]}] && [string is double -strict $m]} {
        return [expr {$m / 1024.0}]
    }
    if {[file exists /proc/self/status]} {
        set fh [open /proc/self/status r]
        while {[gets $fh line] >= 0} {
            if {[regexp {^VmRSS:\s+(\d+)} $line -> kb]} { close $fh; return [expr {$kb / 1024.0}] }
        }
        close $fh
    }
    return 0
}

proc timeit {label body} {
    set t0 [clock milliseconds]
    set m0 [mem_mb]
    set rc [catch {uplevel 1 $body} result]
    set dt [expr {([clock milliseconds] - $t0) / 1000.0}]
    set m1 [mem_mb]
    puts [format "TIMEIT %-30s %8.2fs  mem %8.0f -> %8.0f MB" $label $dt $m0 $m1]
    if {$rc} { return -code error $result }
    return $result
}
