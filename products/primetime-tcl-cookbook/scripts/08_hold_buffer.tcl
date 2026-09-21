#-----------------------------------------------------------------------
# File    : 08_hold_buffer.tcl
# Author  : youbumkim@gmail.com
# Purpose : Insert hold buffers at endpoints with margin against setup
# Tool    : PrimeTime (pt_shell), requires ECO (insert_buffer) capability
# Usage   : source 08_hold_buffer.tcl ; fix_hold_by_buffer -buf lib/DLY2X1 -margin 0.02
#-----------------------------------------------------------------------

# For every hold violator endpoint, insert a delay buffer on the data pin
# only if the setup slack at that endpoint can absorb the buffer delay.
proc fix_hold_by_buffer {args} {
    array set opt {-buf "" -margin 0.010 -max_paths 5000 -buf_delay 0.050 -log hold_fix.log}
    array set opt $args
    if {$opt(-buf) eq ""} { error "-buf lib/cell required" }
    set buf [get_lib_cells $opt(-buf)]
    set log [open $opt(-log) w]
    set paths [get_timing_paths -delay_type min -nworst 1 -max_paths $opt(-max_paths) \
                   -slack_lesser_than 0]
    set n 0
    set skipped 0
    array set done {}
    foreach_in_collection p $paths {
        set ep [get_attribute $p endpoint]
        set en [get_object_name $ep]
        if {[info exists done($en)]} { continue }
        set done($en) 1
        set hold_slack [get_attribute $p slack]
        set setup_slack [get_attribute -quiet $ep max_slack]
        if {![string is double -strict $setup_slack]} { set setup_slack 1e9 }
        set need [expr {-1.0 * $hold_slack + $opt(-margin)}]
        set nbuf [expr {int(ceil($need / $opt(-buf_delay)))}]
        set cost [expr {$nbuf * $opt(-buf_delay)}]
        if {$setup_slack - $cost < $opt(-margin)} {
            puts $log [format "%s hold=%.3f setup=%.3f need=%d bufs SKIP (setup)" $en $hold_slack $setup_slack $nbuf]
            incr skipped
            continue
        }
        for {set i 0} {$i < $nbuf} {incr i} {
            insert_buffer $ep $buf
        }
        incr n
        puts $log [format "%s hold=%.3f setup=%.3f inserted %d x %s" $en $hold_slack $setup_slack $nbuf $opt(-buf)]
    }
    close $log
    update_timing
    puts "endpoints fixed: $n  skipped for setup: $skipped  (log $opt(-log))"
    return $n
}
