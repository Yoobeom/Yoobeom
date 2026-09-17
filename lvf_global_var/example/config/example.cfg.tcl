# ---------------------------------------------------------------------------
# File   : example.cfg.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Configuration of the LVF global-variation example flow
#          (ngspice + BSIM4 example models).  Paths are relative to this file.
# ---------------------------------------------------------------------------

# --- simulator -------------------------------------------------------------
# %DECK% deck file, %LOG% log file, %BASE% deck path without extension
set cfg(sim_cmd)        {ngspice -b -o %LOG% %DECK% > /dev/null 2>&1}
set cfg(result_format)  keyval        ;# keyval (ngspice log, spectre .measure) | mt0 (HSPICE)
set cfg(result_file)    %LOG%         ;# HSPICE: %BASE%.mt0
set cfg(deck_ext)       .sp
set cfg(sim_options)    {{.option reltol=1e-5 abstol=1e-14 vntol=1e-7 chgtol=1e-16}}
set cfg(jobs)           4

# HSPICE example:
#   set cfg(sim_cmd)       {hspice -i %DECK% -o %BASE% > /dev/null 2>&1}
#   set cfg(result_format) mt0
#   set cfg(result_file)   %BASE%.mt0

# --- netlist / models --------------------------------------------------------
set cfg(model_include)  ../models/bsim4_example.sp
set cfg(netlist)        ../cells/std_cells.sp
set cfg(out_dir)        ../out

# --- operating condition and table ------------------------------------------
set cfg(vdd)            1.0
set cfg(temp)           25
set cfg(slews)          {10e-12 30e-12 80e-12}     ;# measured lower..upper input transition [s]
set cfg(loads)          {1e-15 4e-15 12e-15}       ;# output load [F]
set cfg(slew_lower)     0.2
set cfg(slew_upper)     0.8
set cfg(delay_thresh)   0.5
set cfg(t_start)        0.5e-9
set cfg(t_settle)       1.5e-9

# --- perturbation parameters -------------------------------------------------
# hook: instance parameter appended to each device line, %s = deck parameter
#   BSIM4    : delvto (V, additive), mulu0 (multiplier)
#   BSIM-CMG : delvtrand (V, additive), u0mult (multiplier)
set cfg(params)         {vth u0}
set cfg(delta,vth)      0.010        ;# +/- 10 mV
set cfg(delta,u0)       0.02         ;# +/- 2 %
set cfg(hook,vth)       {delvto=%s}
set cfg(hook,u0)        {mulu0=%s}
set cfg(hook_apply,vth) add
set cfg(hook_apply,u0)  mul
# physical sign: shifts are defined as |Vth| increase (slower) and u0 increase (faster).
# BSIM4 delvto adds to the signed vth0 (negative for PMOS) -> PMOS needs -1.
set cfg(shift_sign,N,vth) 1
set cfg(shift_sign,P,vth) -1
set cfg(shift_sign,N,u0)  1
set cfg(shift_sign,P,u0)  1
set cfg(group_sens)     1            ;# also simulate whole-group +/-delta (cross-term check)

# --- device grouping (model name regex -> global variation group) --------------
set cfg(group_map)      {{^nch} N {^pch} P}
set cfg(supply_map)     {VDD vdd VSS 0 VNW vdd VPW 0}

# --- variation sigma (example values, replace by PDK data) -------------------
# global 1-sigma per group/param (used for corner unit "sigma")
set cfg(sigma_g,N,vth)  0.015        ;# V
set cfg(sigma_g,P,vth)  0.015        ;# V
set cfg(sigma_g,N,u0)   0.03         ;# relative
set cfg(sigma_g,P,u0)   0.03         ;# relative
# mismatch 1-sigma per device: {pelgrom A} sigma=A/sqrt(W_um*L_um*NF*M), or {const s}
set cfg(sigma_mm,N,vth) {pelgrom 2.0e-3}   ;# A_vt = 2 mV.um
set cfg(sigma_mm,P,vth) {pelgrom 2.2e-3}
set cfg(sigma_mm,N,u0)  {pelgrom 1.0e-2}   ;# 1 %.um
set cfg(sigma_mm,P,u0)  {pelgrom 1.0e-2}

# output edge driven by each group (sign rule of contrib_to_global.tcl)
set cfg(pull,N)         fall
set cfg(pull,P)         rise

# --- cells and arcs ----------------------------------------------------------
# arc keys: name in in_dir out out_dir side {pin value ...} when "<liberty when>"
set cfg(cells) {INV_X1 NAND2_X1 NOR2_X1}
set cfg(lib_function,INV_X1)   "!A"
set cfg(lib_function,NAND2_X1) "!(A*B)"
set cfg(lib_function,NOR2_X1)  "!(A+B)"

set cfg(arcs,INV_X1) {
    {name A_r_ZN_f  in A in_dir rise out ZN out_dir fall side {}    when ""}
    {name A_f_ZN_r  in A in_dir fall out ZN out_dir rise side {}    when ""}
}
set cfg(arcs,NAND2_X1) {
    {name A_r_ZN_f  in A in_dir rise out ZN out_dir fall side {B 1} when "B"}
    {name A_f_ZN_r  in A in_dir fall out ZN out_dir rise side {B 1} when "B"}
    {name B_r_ZN_f  in B in_dir rise out ZN out_dir fall side {A 1} when "A"}
    {name B_f_ZN_r  in B in_dir fall out ZN out_dir rise side {A 1} when "A"}
}
set cfg(arcs,NOR2_X1) {
    {name A_r_ZN_f  in A in_dir rise out ZN out_dir fall side {B 0} when "!B"}
    {name A_f_ZN_r  in A in_dir fall out ZN out_dir rise side {B 0} when "!B"}
    {name B_r_ZN_f  in B in_dir rise out ZN out_dir fall side {A 0} when "!A"}
    {name B_f_ZN_r  in B in_dir fall out ZN out_dir rise side {A 0} when "!A"}
}
