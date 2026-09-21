#-----------------------------------------------------------------------
# File    : 09_custom_report_timing.tcl
# Author  : youbumkim@gmail.com
# Purpose : Standard report_timing options bundled for signoff review
# Tool    : PrimeTime (pt_shell)
# Usage   : source 09_custom_report_timing.tcl ; rt_full CLK 20 setup.rpt
#-----------------------------------------------------------------------

# Full-detail report used for path review: clock expanded, input pins,
# nets, transition, capacitance, derates, and 3 significant digits.
proc rt_full {group nworst_paths out {delay_type max}} {
    redirect -file $out {
        report_timing -group $group -delay_type $delay_type \
            -max_paths $nworst_paths -nworst 1 \
            -path_type full_clock_expanded \
            -input_pins -nets -transition_time -capacitance \
            -derate -crpr -significant_digits 3 -nosplit
    }
    puts "wrote $out"
}

# Short end-only list used for tracking: one line per endpoint.
proc rt_endpoints {group max_paths out {delay_type max}} {
    redirect -file $out {
        report_timing -group $group -delay_type $delay_type \
            -max_paths $max_paths -nworst 1 -path_type end -nosplit
    }
    puts "wrote $out"
}

# Path-based analysis for the worst N paths before ECO decisions.
proc rt_pba {group max_paths out} {
    redirect -file $out {
        report_timing -group $group -delay_type max -max_paths $max_paths \
            -pba_mode path -path_type full_clock_expanded \
            -input_pins -nets -transition_time -capacitance -nosplit
    }
    puts "wrote $out"
}

# Bundle for all path groups at once.
proc rt_all_groups {dir {max_paths 50}} {
    file mkdir $dir
    foreach_in_collection g [get_path_groups] {
        set gn [get_object_name $g]
        set safe [string map {/ _ * all} $gn]
        rt_full      $gn $max_paths $dir/setup_${safe}.rpt max
        rt_full      $gn $max_paths $dir/hold_${safe}.rpt  min
        rt_endpoints $gn 2000       $dir/setup_${safe}_end.rpt max
    }
}
