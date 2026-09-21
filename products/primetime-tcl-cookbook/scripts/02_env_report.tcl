#-----------------------------------------------------------------------
# File    : 02_env_report.tcl
# Author  : youbumkim@gmail.com
# Purpose : Capture the analysis environment for reproducibility
# Tool    : PrimeTime (pt_shell)
# Usage   : source 02_env_report.tcl ; write_env_report env.rpt
#-----------------------------------------------------------------------

proc write_env_report {out} {
    set fh [open $out w]
    puts $fh "# Environment snapshot [clock format [clock seconds]]"
    puts $fh "tool_version      : [get_app_var sh_product_version]"
    puts $fh "design            : [get_object_name [current_design]]"
    puts $fh "host              : [info hostname]"
    puts $fh "cwd               : [pwd]"
    puts $fh ""
    puts $fh "# Application variables that affect results"
    foreach v {
        timing_remove_clock_reconvergence_pessimism
        timing_save_pin_arrival_and_slack
        timing_report_unconstrained_paths
        timing_enable_through_paths
        si_enable_analysis
        timing_disable_recovery_removal_checks
        timing_clock_reconvergence_pessimism
        timing_crpr_threshold_ps
        timing_input_port_default_clock
        timing_all_clocks_propagated
        timing_gclock_source_network_num_master_registers
        timing_use_enhanced_capacitance_modeling
        rc_input_threshold_pct_rise
        rc_output_threshold_pct_rise
        rc_slew_lower_threshold_pct_rise
        rc_slew_upper_threshold_pct_rise
    } {
        if {[catch {set val [get_app_var $v]}]} { set val "(n/a)" }
        puts $fh [format "%-50s : %s" $v $val]
    }
    puts $fh ""
    puts $fh "# Libraries"
    foreach_in_collection lib [get_libs] {
        puts $fh "  [get_object_name $lib]  [get_attribute -quiet $lib source_file_name]"
    }
    puts $fh ""
    puts $fh "# Clocks"
    foreach_in_collection c [get_clocks] {
        set gen [get_attribute -quiet $c is_generated]
        puts $fh [format "  %-30s period=%-8s generated=%s" \
            [get_object_name $c] [get_attribute $c period] $gen]
    }
    puts $fh ""
    puts $fh "# Derates"
    redirect -variable d { report_timing_derate }
    puts $fh $d
    close $fh
    puts "wrote $out"
}
