#-----------------------------------------------------------------------
# File    : 07_bucket_violators.tcl
# Author  : youbumkim@gmail.com
# Purpose : Group setup/hold violators by block, clock pair, and severity
# Tool    : PrimeTime (pt_shell)
# Usage   : source 07_bucket_violators.tcl ; bucket_violators -depth 2 -out v.csv
#-----------------------------------------------------------------------

proc bucket_violators {args} {
    array set opt {-depth 2 -delay_type max -max_paths 50000 -out "" -group {}}
    array set opt $args
    set cmd [list get_timing_paths -delay_type $opt(-delay_type) -nworst 1 \
                 -max_paths $opt(-max_paths) -slack_lesser_than 0]
    if {$opt(-group) ne ""} { lappend cmd -group $opt(-group) }
    set paths [eval $cmd]

    array set cnt {}
    array set wns {}
    array set tns {}
    set rows {}
    foreach_in_collection p $paths {
        set s  [get_attribute $p slack]
        set sp [get_object_name [get_attribute $p startpoint]]
        set ep [get_object_name [get_attribute $p endpoint]]
        set lc [get_object_name [get_attribute -quiet $p startpoint_clock]]
        set cc [get_object_name [get_attribute -quiet $p endpoint_clock]]
        set sblk [join [lrange [split $sp "/"] 0 [expr {$opt(-depth) - 1}]] "/"]
        set eblk [join [lrange [split $ep "/"] 0 [expr {$opt(-depth) - 1}]] "/"]
        if {$s <= -0.100} { set sev S1 } elseif {$s <= -0.030} { set sev S2 } else { set sev S3 }
        set key "$sblk|$eblk|$lc|$cc"
        if {![info exists cnt($key)]} { set cnt($key) 0; set wns($key) 0; set tns($key) 0.0 }
        incr cnt($key)
        set tns($key) [expr {$tns($key) + $s}]
        if {$s < $wns($key)} { set wns($key) $s }
        lappend rows [list $s $sev $sblk $eblk $lc $cc $sp $ep]
    }

    puts [format "%-28s %-28s %-14s %-14s %6s %9s %10s" FROM_BLOCK TO_BLOCK LAUNCH CAPTURE N WNS TNS]
    set keys {}
    foreach k [array names cnt] { lappend keys [list $k $tns($k)] }
    foreach kk [lsort -real -index 1 $keys] {
        set k [lindex $kk 0]
        lassign [split $k "|"] a b l c
        puts [format "%-28s %-28s %-14s %-14s %6d %9.3f %10.3f" $a $b $l $c $cnt($k) $wns($k) $tns($k)]
    }

    if {$opt(-out) ne ""} {
        set fh [open $opt(-out) w]
        puts $fh "slack,severity,from_block,to_block,launch_clock,capture_clock,startpoint,endpoint"
        foreach r [lsort -real -index 0 $rows] { puts $fh [join $r ","] }
        close $fh
        puts "wrote [llength $rows] violators to $opt(-out)"
    }
    return $rows
}
