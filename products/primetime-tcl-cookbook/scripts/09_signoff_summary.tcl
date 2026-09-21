#-----------------------------------------------------------------------
# File    : 09_signoff_summary.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : One JSON file per run with everything a dashboard needs
# Tool    : PrimeTime (pt_shell)
# Usage   : source 09_csv_json.tcl ; source 09_signoff_summary.tcl
#           write_signoff_summary summary.json func ss0p72v125c
#-----------------------------------------------------------------------

proc group_metrics {delay_type} {
    set out {}
    foreach_in_collection g [get_path_groups] {
        set gn [get_object_name $g]
        set paths [get_timing_paths -group $g -delay_type $delay_type -nworst 1 \
                       -max_paths 100000 -slack_lesser_than 0]
        set wns 0.0; set tns 0.0; set n 0
        foreach_in_collection p $paths {
            set s [get_attribute $p slack]
            incr n
            set tns [expr {$tns + $s}]
            if {$s < $wns} { set wns $s }
        }
        lappend out [json_obj [list group $gn wns [format %.4f $wns] tns [format %.4f $tns] nvp $n]]
    }
    return $out
}

proc write_signoff_summary {file mode corner} {
    set setup [group_metrics max]
    set hold  [group_metrics min]
    redirect -variable drv { report_constraint -all_violators -max_transition -max_capacitance -nosplit }
    set n_drv [regexp -all {\(VIOLATED\)} $drv]
    set kv [list \
        design   [get_object_name [current_design]] \
        mode     $mode \
        corner   $corner \
        date     [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"] \
        tool     [get_app_var sh_product_version] \
        setup    [json_arr $setup 1] \
        hold     [json_arr $hold 1] \
        drv_violators $n_drv]
    set fh [open $file w]
    puts $fh [json_obj $kv {setup hold}]
    close $fh
    puts "wrote $file"
}
