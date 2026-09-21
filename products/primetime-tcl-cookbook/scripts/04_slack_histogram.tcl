#-----------------------------------------------------------------------
# File    : 04_slack_histogram.tcl
# Author  : youbumkim@gmail.com
# Purpose : Endpoint slack histogram with text bars
# Tool    : PrimeTime (pt_shell)
# Usage   : source 04_slack_histogram.tcl ; slack_histogram -bin 0.020 -max 10000
#-----------------------------------------------------------------------

# Bins worst slack per endpoint (nworst 1) and prints a histogram.
# Requires timing_save_pin_arrival_and_slack for the pin-based mode.
proc slack_histogram {args} {
    array set opt {-bin 0.020 -min -0.500 -max_paths 20000 -group {} -delay_type max -width 50}
    array set opt $args

    set cmd [list get_timing_paths -delay_type $opt(-delay_type) -nworst 1 \
                 -max_paths $opt(-max_paths) -slack_lesser_than 1e9]
    if {$opt(-group) ne ""} { lappend cmd -group $opt(-group) }
    set paths [eval $cmd]

    array set hist {}
    set total 0
    set neg 0
    set worst 1e9
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        if {![string is double -strict $s]} { continue }
        incr total
        if {$s < 0} { incr neg }
        if {$s < $worst} { set worst $s }
        if {$s < $opt(-min)} {
            set key "below"
        } else {
            set key [expr {int(floor($s / $opt(-bin)))}]
        }
        if {[info exists hist($key)]} { incr hist($key) } else { set hist($key) 1 }
    }
    if {$total == 0} { puts "no paths"; return }

    set maxc 1
    foreach k [array names hist] { if {$hist($k) > $maxc} { set maxc $hist($k) } }

    puts "paths=$total negative=$neg worst=[format %.3f $worst] bin=$opt(-bin)"
    if {[info exists hist(below)]} {
        puts [format "%10s  %6d %s" "<[format %.3f $opt(-min)]" $hist(below) \
              [string repeat "#" [expr {int($hist(below) * $opt(-width) / $maxc)}]]]
        unset hist(below)
    }
    foreach k [lsort -integer [array names hist]] {
        set lo [expr {$k * $opt(-bin)}]
        set bar [string repeat "#" [expr {int($hist($k) * $opt(-width) / $maxc)}]]
        puts [format "%10s  %6d %s" [format %.3f $lo] $hist($k) $bar]
    }
}
