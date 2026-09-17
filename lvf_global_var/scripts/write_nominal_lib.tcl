#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : write_nominal_lib.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Write a minimal Liberty file (delay / transition tables and LVF
#          ocv_sigma tables) from the nominal simulation results of the flow.
#          Used for the example regression of apply_to_liberty.tcl; production
#          libraries come from the characterization tool.
# Usage  :
#   tclsh write_nominal_lib.tcl -cfg example.cfg.tcl -nominal out/nominal.csv \
#         [-sigma out/local_sigma.csv] -o lib/example_nominal.lib [-libname NAME]
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

proc fmtlist {vals scale} {
    return [join [lmap v $vals {format %.6g [expr {$v * $scale}]}] ", "]
}

proc table_text {name tmpl data nslew nload indent} {
    # data: dict "j,k" -> value in ps
    set t "${indent}$name ($tmpl) \{\n"
    append t "${indent}  values ( \\\n"
    for {set j 0} {$j < $nslew} {incr j} {
        set row {}
        for {set k 0} {$k < $nload} {incr k} {
            set v ""
            if {[dict exists $data "$j,$k"]} { set v [dict get $data "$j,$k"] }
            lappend row [expr {$v eq "" ? "0" : [format %.6g $v]}]
        }
        set sep [expr {$j < $nslew - 1 ? "," : ""}]
        append t "${indent}    \"[join $row {, }]\"$sep \\\n"
    }
    append t "${indent}  );\n"
    append t "${indent}\}\n"
    return $t
}

proc main {argv} {
    set opt [::lvfgv::parse_args $argv {cfg nominal sigma o libname} {}]
    foreach k {cfg nominal o} {
        if {![dict exists $opt $k]} {
            puts stderr "usage: tclsh write_nominal_lib.tcl -cfg <cfg> -nominal <nominal.csv> \[-sigma <local_sigma.csv>\] -o <lib> \[-libname NAME\]"
            exit 1
        }
    }
    ::lvfgv::load_cfg [dict get $opt cfg]
    set libname example_lvfgv
    if {[dict exists $opt libname]} { set libname [dict get $opt libname] }
    lassign [::lvfgv::csv_read [dict get $opt nominal]] h rows
    set nom [dict create]
    foreach r $rows {
        dict set nom "[dict get $r cell],[dict get $r arc],[dict get $r meas],[dict get $r slew_idx],[dict get $r load_idx]" [dict get $r v0]
    }
    set sig [dict create]
    if {[dict exists $opt sigma]} {
        lassign [::lvfgv::csv_read [dict get $opt sigma]] h2 srows
        foreach r $srows {
            dict set sig "[dict get $r cell],[dict get $r arc],[dict get $r meas],[dict get $r slew_idx],[dict get $r load_idx]" [dict get $r sigma_local]
        }
    }
    set slews $::lvfgv::cfg(slews)
    set loads $::lvfgv::cfg(loads)
    set nslew [llength $slews]
    set nload [llength $loads]
    set tmpl "delay_${nslew}x${nload}"

    set out {}
    lappend out "/* Liberty written by write_nominal_lib.tcl (LVF global variation flow example) */"
    lappend out "library ($libname) \{"
    lappend out "  delay_model : table_lookup;"
    lappend out "  time_unit : \"1ps\";"
    lappend out "  voltage_unit : \"1V\";"
    lappend out "  current_unit : \"1mA\";"
    lappend out "  leakage_power_unit : \"1nW\";"
    lappend out "  pulling_resistance_unit : \"1kohm\";"
    lappend out "  capacitive_load_unit (1,ff);"
    lappend out "  nom_process : 1;"
    lappend out "  nom_temperature : $::lvfgv::cfg(temp);"
    lappend out "  nom_voltage : $::lvfgv::cfg(vdd);"
    lappend out "  operating_conditions (nom) \{"
    lappend out "    process : 1;"
    lappend out "    temperature : $::lvfgv::cfg(temp);"
    lappend out "    voltage : $::lvfgv::cfg(vdd);"
    lappend out "    tree_type : balanced_tree;"
    lappend out "  \}"
    lappend out "  default_operating_conditions : nom;"
    set lo [expr {int(round($::lvfgv::cfg(slew_lower)*100))}]
    set hi [expr {int(round($::lvfgv::cfg(slew_upper)*100))}]
    set th [expr {int(round($::lvfgv::cfg(delay_thresh)*100))}]
    lappend out "  slew_lower_threshold_pct_rise : $lo;"
    lappend out "  slew_lower_threshold_pct_fall : $lo;"
    lappend out "  slew_upper_threshold_pct_rise : $hi;"
    lappend out "  slew_upper_threshold_pct_fall : $hi;"
    lappend out "  input_threshold_pct_rise : $th;"
    lappend out "  input_threshold_pct_fall : $th;"
    lappend out "  output_threshold_pct_rise : $th;"
    lappend out "  output_threshold_pct_fall : $th;"
    lappend out "  slew_derate_from_library : 1;"
    lappend out "  default_max_transition : [format %.6g [expr {[::lvfgv::lmax $slews]*1e12}]];"
    lappend out "  lu_table_template ($tmpl) \{"
    lappend out "    variable_1 : input_net_transition;"
    lappend out "    variable_2 : total_output_net_capacitance;"
    lappend out "    index_1 (\"[fmtlist $slews 1e12]\");"
    lappend out "    index_2 (\"[fmtlist $loads 1e15]\");"
    lappend out "  \}"

    foreach cell $::lvfgv::cfg(cells) {
        lappend out "  cell ($cell) \{"
        lappend out "    area : 1.0;"
        # group arcs by out pin / related pin / when
        set groups [dict create]
        set inpins {}
        foreach arc $::lvfgv::cfg(arcs,$cell) {
            set in [dict get $arc in]
            if {$in ni $inpins} { lappend inpins $in }
            set when ""
            if {[dict exists $arc when]} { set when [dict get $arc when] }
            set gk "[dict get $arc out]\t$in\t$when"
            dict set groups $gk [dict get $arc out_dir] $arc
        }
        set outpins {}
        dict for {gk d} $groups {
            set op [lindex [split $gk \t] 0]
            if {$op ni $outpins} { lappend outpins $op }
        }
        foreach in $inpins {
            lappend out "    pin ($in) \{"
            lappend out "      direction : input;"
            lappend out "      capacitance : 0.5;"
            lappend out "    \}"
        }
        foreach op $outpins {
            lappend out "    pin ($op) \{"
            lappend out "      direction : output;"
            if {[info exists ::lvfgv::cfg(lib_function,$cell)]} {
                lappend out "      function : \"$::lvfgv::cfg(lib_function,$cell)\";"
            }
            dict for {gk d} $groups {
                lassign [split $gk \t] pout pin when
                if {$pout ne $op} { continue }
                lappend out "      timing () \{"
                lappend out "        related_pin : \"$pin\";"
                set sense ""
                dict for {od arc} $d {
                    set s [expr {[dict get $arc in_dir] eq $od ? "positive_unate" : "negative_unate"}]
                    if {$sense eq ""} { set sense $s } elseif {$sense ne $s} { set sense non_unate }
                }
                lappend out "        timing_sense : $sense;"
                if {$when ne ""} { lappend out "        when : \"$when\";" }
                lappend out "        timing_type : combinational;"
                foreach od {rise fall} {
                    if {![dict exists $d $od]} { continue }
                    set arc [dict get $d $od]
                    set an [dict get $arc name]
                    foreach {meas tname sname} [list delay cell_$od ocv_sigma_cell_$od trans ${od}_transition ocv_sigma_${od}_transition] {
                        set data [dict create]
                        set sdata [dict create]
                        for {set j 0} {$j < $nslew} {incr j} {
                            for {set k 0} {$k < $nload} {incr k} {
                                set key "$cell,$an,$meas,$j,$k"
                                if {[dict exists $nom $key] && [dict get $nom $key] ne ""} {
                                    dict set data "$j,$k" [expr {[dict get $nom $key] * 1e12}]
                                }
                                if {[dict exists $sig $key] && [dict get $sig $key] ne ""} {
                                    dict set sdata "$j,$k" [expr {[dict get $sig $key] * 1e12}]
                                }
                            }
                        }
                        lappend out [string trimright [table_text $tname $tmpl $data $nslew $nload "        "] \n]
                        if {[dict size $sdata] > 0} {
                            set tt [table_text $sname $tmpl $sdata $nslew $nload "        "]
                            regsub {\{\n} $tt "\{\n          sigma_type : early_and_late;\n" tt
                            lappend out [string trimright $tt \n]
                        }
                    }
                }
                lappend out "      \}"
            }
            lappend out "    \}"
        }
        lappend out "  \}"
    }
    lappend out "\}"
    set f [dict get $opt o]
    file mkdir [file dirname $f]
    set fh [open $f w]
    puts $fh [join $out \n]
    close $fh
    ::lvfgv::msg "wrote $f"
}
main $argv
