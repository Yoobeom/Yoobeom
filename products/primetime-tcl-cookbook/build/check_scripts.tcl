#-----------------------------------------------------------------------
# File    : check_scripts.tcl
# Author  : youbumkim@gmail.com
# Purpose : Parse-check every script in scripts/ with stubbed commands
# Usage   : tclsh build/check_scripts.tcl
#-----------------------------------------------------------------------
foreach f [lsort [glob [file join [file dirname [info script]] .. scripts *.tcl]]] {
    set fh [open $f r]; set s [read $fh]; close $fh
    if {![info complete $s]} { puts "INCOMPLETE $f" }
    # parse each proc body by defining procs in a slave interp with stub commands
    # template scripts read files and call source with flags; parse-check only
    if {[string match "*_setup.tcl" $f]} { continue }
    set ip [interp create]
    $ip eval {
        proc unknown {args} { return "" }
    }
    if {[catch {$ip eval $s} err]} { puts "EVAL-ERR $f : $err" }
    interp delete $ip
}
puts "check finished"
