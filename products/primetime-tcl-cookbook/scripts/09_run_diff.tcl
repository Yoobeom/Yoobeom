#-----------------------------------------------------------------------
# File    : 09_run_diff.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Compare endpoint slack between two runs (CSV from path_table)
# Tool    : any Tcl 8.x (runs outside pt_shell too)
# Usage   : tclsh 09_run_diff.tcl old.csv new.csv 0.010
#-----------------------------------------------------------------------

# Input CSVs must have header: slack,...,endpoint (endpoint = last column
# of bucket_violators output, or any file with 'slack' and 'endpoint').
proc load_ep_slack {file} {
    set fh [open $file r]
    set hdr [split [gets $fh] ","]
    set is [lsearch -exact $hdr slack]
    set ie [lsearch -exact $hdr endpoint]
    if {$is < 0 || $ie < 0} { error "$file: need slack and endpoint columns" }
    array set m {}
    while {[gets $fh line] >= 0} {
        set f [split $line ","]
        set ep [lindex $f $ie]
        set s  [lindex $f $is]
        if {![info exists m($ep)] || $s < $m($ep)} { set m($ep) $s }
    }
    close $fh
    return [array get m]
}

proc run_diff {old new {thresh 0.010}} {
    array set a [load_ep_slack $old]
    array set b [load_ep_slack $new]
    set improved {}; set degraded {}; set new_ep {}; set gone {}
    foreach ep [array names b] {
        if {![info exists a($ep)]} { lappend new_ep [list $ep $b($ep)]; continue }
        set d [expr {$b($ep) - $a($ep)}]
        if {$d > $thresh}       { lappend improved [list $ep $a($ep) $b($ep) $d] }
        if {$d < -1 * $thresh}  { lappend degraded [list $ep $a($ep) $b($ep) $d] }
    }
    foreach ep [array names a] {
        if {![info exists b($ep)]} { lappend gone [list $ep $a($ep)] }
    }
    puts "endpoints old=[array size a] new=[array size b]"
    puts "improved=[llength $improved] degraded=[llength $degraded] new=[llength $new_ep] fixed/gone=[llength $gone]"
    puts "\nDEGRADED (worst first)"
    foreach r [lsort -real -index 3 $degraded] {
        lassign $r ep o n d
        puts [format "  %9.3f -> %9.3f (%+.3f)  %s" $o $n $d $ep]
    }
    puts "\nNEW VIOLATORS"
    foreach r [lsort -real -index 1 $new_ep] {
        lassign $r ep n
        puts [format "  %9.3f  %s" $n $ep]
    }
}

if {[info exists argv] && [llength $argv] >= 2} {
    run_diff [lindex $argv 0] [lindex $argv 1] [expr {[llength $argv] > 2 ? [lindex $argv 2] : 0.010}]
}
