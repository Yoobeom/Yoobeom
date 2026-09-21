#-----------------------------------------------------------------------
# File    : 10_dmsa_setup.tcl
# Author  : youbumkim@gmail.com
# Purpose : Distributed multi-scenario (DMSA) bring-up from a corner table
# Tool    : PrimeTime DMSA (pt_shell -multi_scenario)
# Usage   : pt_shell -multi_scenario -f 10_dmsa_setup.tcl
#-----------------------------------------------------------------------

# Corner table: name  lib_db  spef  derate_late derate_early
set corners {
    {ss_rcworst   stdcell_ss0p72v125c.db  top.rcworst_125c.spef.gz   1.05 0.95}
    {ss_cworst    stdcell_ss0p72v125c.db  top.cworst_125c.spef.gz    1.05 0.95}
    {ff_rcbest    stdcell_ff0p88vm40c.db  top.rcbest_m40c.spef.gz    1.00 0.92}
}
set modes {func scan}

set_app_var multi_scenario_working_directory ./dmsa_work
set_app_var multi_scenario_merged_error_log  ./dmsa_work/merged_errors.log
set_host_options -num_processes 6 -max_cores 4

# Every scenario shares the netlist read; corner-specific data is small.
foreach mode $modes {
    foreach c $corners {
        lassign $c cname lib spef dl de
        set fh [open ./dmsa_work/${mode}_${cname}.tcl w]
        puts $fh "set_app_var link_path \"* ./lib/$lib\""
        puts $fh "read_verilog ./netlist/top.v.gz"
        puts $fh "current_design top"
        puts $fh "link_design"
        puts $fh "read_parasitics -format spef ./spef/$spef"
        puts $fh "source ./sdc/top_${mode}.sdc"
        puts $fh "set_timing_derate -cell_delay -net_delay -late $dl"
        puts $fh "set_timing_derate -cell_delay -net_delay -early $de"
        puts $fh "set_propagated_clock \[all_clocks\]"
        close $fh
        create_scenario -name ${mode}_${cname} \
            -specific_data ./dmsa_work/${mode}_${cname}.tcl
    }
}

current_session -all
remote_execute { update_timing -full }

# Merged reports across all scenarios: worst per endpoint.
report_timing -max_paths 100 -nworst 1 -path_type end > ./dmsa_work/merged_setup_end.rpt
report_timing -delay_type min -max_paths 100 -nworst 1 -path_type end > ./dmsa_work/merged_hold_end.rpt
report_constraint -all_violators > ./dmsa_work/merged_constraint.rpt
