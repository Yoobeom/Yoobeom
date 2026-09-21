#-----------------------------------------------------------------------
# File    : 02_session_setup.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Reproducible PrimeTime session bring-up from a config array
# Tool    : PrimeTime (pt_shell)
# Usage   : pt_shell -f 02_session_setup.tcl
#-----------------------------------------------------------------------

# ---- 1. Configuration block. Edit only this section per block/corner.
set cfg(design)      top
set cfg(netlist)     ./netlist/top.v.gz
set cfg(link_path)   [list * ./lib/stdcell_ss0p72v125c.db ./lib/sram_ss0p72v125c.db]
set cfg(spef)        ./spef/top.rcworst_125c.spef.gz
set cfg(sdc)         ./sdc/top_func.sdc
set cfg(corner)      ss0p72v125c_rcworst
set cfg(mode)        func
set cfg(rpt_dir)     ./rpt/$cfg(mode)_$cfg(corner)
set cfg(derate_late) 1.05
set cfg(derate_early) 0.95

file mkdir $cfg(rpt_dir)

# ---- 2. Application variables that change analysis results.
set_app_var search_path {. ./lib ./netlist ./sdc ./spef}
set_app_var link_path $cfg(link_path)
set_app_var timing_remove_clock_reconvergence_pessimism true
set_app_var timing_save_pin_arrival_and_slack true
set_app_var timing_report_unconstrained_paths true
set_app_var si_enable_analysis false
set_app_var timing_enable_through_paths true
set_app_var sh_continue_on_error true

# ---- 3. Read design.
read_verilog $cfg(netlist)
current_design $cfg(design)
link_design

# ---- 4. Parasitics.
read_parasitics -format spef $cfg(spef)

# ---- 5. Constraints and derates.
source -echo -verbose $cfg(sdc) > $cfg(rpt_dir)/sdc_source.log
set_timing_derate -cell_delay -net_delay -late $cfg(derate_late)
set_timing_derate -cell_delay -net_delay -early $cfg(derate_early)
set_propagated_clock [all_clocks]

# ---- 6. First timing update and sanity reports.
update_timing -full
redirect -file $cfg(rpt_dir)/check_timing.rpt   { check_timing -verbose }
redirect -file $cfg(rpt_dir)/analysis_cov.rpt   { report_analysis_coverage }
redirect -file $cfg(rpt_dir)/qor.rpt            { report_qor }
redirect -file $cfg(rpt_dir)/global_slack.rpt   { report_global_timing }

# ---- 7. Save the session so ECO or debug can resume without re-linking.
save_session $cfg(rpt_dir)/session
puts "Session ready: $cfg(mode)/$cfg(corner)"
