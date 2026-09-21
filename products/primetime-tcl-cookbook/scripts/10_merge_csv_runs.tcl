#-----------------------------------------------------------------------
# File    : 10_merge_csv_runs.tcl
# Author  : youbumkim@gmail.com
# Purpose : Merge per-corner violator CSVs into one worst-per-endpoint table
# Tool    : any Tcl 8.x (runs outside pt_shell)
# Usage   : tclsh 10_merge_csv_runs.tcl merged.csv rpt/*/violators.csv
#-----------------------------------------------------------------------

# Input files come from bucket_violators -out. The corner name is taken
# from the parent directory of each CSV.
proc merge_runs {out files} {
    array set worst {}
    array set corner {}
    array set ncorner {}
    foreach f $files {
        set cname [file tail [file dirname $f]]
        set fh [open $f r]
        set hdr [split [gets $fh] ","]
        set is [lsearch -exact $hdr slack]
        set ie [lsearch -exact $hdr endpoint]
        while {[gets $fh line] >= 0} {
            set fl [split $line ","]
            set ep [lindex $fl $ie]
            set s  [lindex $fl $is]
            if {![info exists ncorner($ep)]} { set ncorner($ep) 0 }
            incr ncorner($ep)
            if {![info exists worst($ep)] || $s < $worst($ep)} {
                set worst($ep) $s
                set corner($ep) $cname
            }
        }
        close $fh
    }
    set rows {}
    foreach ep [array names worst] {
        lappend rows [list $worst($ep) $corner($ep) $ncorner($ep) $ep]
    }
    set rows [lsort -real -index 0 $rows]
    set oh [open $out w]
    puts $oh "worst_slack,worst_corner,n_corners_failing,endpoint"
    foreach r $rows { puts $oh [join $r ","] }
    close $oh
    puts "merged [llength $rows] endpoints from [llength $files] files -> $out"
}

if {[info exists argv] && [llength $argv] >= 2} {
    merge_runs [lindex $argv 0] [lrange $argv 1 end]
}
