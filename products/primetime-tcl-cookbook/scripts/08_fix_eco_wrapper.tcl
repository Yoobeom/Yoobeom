#-----------------------------------------------------------------------
# File    : 08_fix_eco_wrapper.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Wrapper around fix_eco_timing / fix_eco_drc with before/after
# Tool    : PrimeTime (pt_shell), requires PrimeTime ECO license
# Usage   : source 08_fix_eco_wrapper.tcl ; run_fix_eco setup
#-----------------------------------------------------------------------

proc wns_tns {{delay_type max}} {
    set paths [get_timing_paths -delay_type $delay_type -nworst 1 -max_paths 100000 -slack_lesser_than 0]
    set wns 0.0
    set tns 0.0
    set n 0
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        incr n
        set tns [expr {$tns + $s}]
        if {$s < $wns} { set wns $s }
    }
    return [list $wns $tns $n]
}

# type: setup | hold | drc
proc run_fix_eco {type args} {
    array set opt {-methods {size_cell} -buffer_list {} -slack_lesser_than 0 -cell_pattern {}}
    array set opt $args
    switch -- $type {
        setup { lassign [wns_tns max] w0 t0 n0 }
        hold  { lassign [wns_tns min] w0 t0 n0 }
        drc   { set w0 0; set t0 0; set n0 0 }
    }
    switch -- $type {
        setup {
            fix_eco_timing -type setup -methods $opt(-methods) \
                -slack_lesser_than $opt(-slack_lesser_than)
        }
        hold {
            set cmd [list fix_eco_timing -type hold -methods $opt(-methods)]
            if {$opt(-buffer_list) ne ""} { lappend cmd -buffer_list $opt(-buffer_list) }
            eval $cmd
        }
        drc {
            set cmd [list fix_eco_drc -type max_transition -methods $opt(-methods)]
            if {$opt(-buffer_list) ne ""} { lappend cmd -buffer_list $opt(-buffer_list) }
            eval $cmd
            set cmd [list fix_eco_drc -type max_capacitance -methods $opt(-methods)]
            if {$opt(-buffer_list) ne ""} { lappend cmd -buffer_list $opt(-buffer_list) }
            eval $cmd
        }
    }
    update_timing
    switch -- $type {
        setup { lassign [wns_tns max] w1 t1 n1 }
        hold  { lassign [wns_tns min] w1 t1 n1 }
        drc   { set w1 0; set t1 0; set n1 0 }
    }
    puts [format "%-6s before: WNS %.3f TNS %.3f N %d" $type $w0 $t0 $n0]
    puts [format "%-6s after : WNS %.3f TNS %.3f N %d" $type $w1 $t1 $n1]
}
