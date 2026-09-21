#-----------------------------------------------------------------------
# File    : 10_scenario_loop.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Run a per-scenario proc remotely and collect results
# Tool    : PrimeTime DMSA (pt_shell -multi_scenario)
# Usage   : source 10_scenario_loop.tcl ; collect_wns_per_scenario
#-----------------------------------------------------------------------

# Each remote slave writes one CSV line; the master joins them.
proc collect_wns_per_scenario {{dir ./dmsa_work/wns}} {
    file mkdir $dir
    current_session -all
    # Braces would keep $dir unsubstituted on the master; bake it in first.
    set body [string map [list @DIR@ $dir] {
        set paths [get_timing_paths -delay_type max -nworst 1 -max_paths 100000 -slack_lesser_than 0]
        set wns 0.0; set tns 0.0; set n 0
        foreach_in_collection p $paths {
            set s [get_attribute $p slack]
            incr n; set tns [expr {$tns + $s}]
            if {$s < $wns} { set wns $s }
        }
        set fh [open @DIR@/[current_scenario].csv w]
        puts $fh "[current_scenario],$wns,$tns,$n"
        close $fh
    }]
    remote_execute $body
    puts [format "%-24s %9s %10s %7s" SCENARIO WNS TNS NVP]
    foreach f [lsort [glob -nocomplain $dir/*.csv]] {
        set fh [open $f r]
        lassign [split [gets $fh] ","] sc w t n
        close $fh
        puts [format "%-24s %9.3f %10.3f %7d" $sc $w $t $n]
    }
}

# Which scenario is worst for a given endpoint? Useful before ECO.
proc worst_scenario_for {endpoint {dir ./dmsa_work/ep}} {
    file mkdir $dir
    current_session -all
    remote_execute "
        set p \[get_timing_paths -to $endpoint -nworst 1 -max_paths 1\]
        set fh \[open $dir/\[current_scenario\].txt w\]
        if {\$p ne \"\"} { puts \$fh \"\[current_scenario\] \[get_attribute \$p slack\]\" } else { puts \$fh \"\[current_scenario\] NA\" }
        close \$fh
    "
    set rows {}
    foreach f [glob -nocomplain $dir/*.txt] {
        set fh [open $f r]
        lassign [gets $fh] sc s
        close $fh
        if {[string is double -strict $s]} { lappend rows [list $sc $s] }
    }
    set rows [lsort -real -index 1 $rows]
    foreach r $rows { puts [format "  %-24s %9.3f" [lindex $r 0] [lindex $r 1]] }
    return [lindex $rows 0]
}
