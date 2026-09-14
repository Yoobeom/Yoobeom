#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : contrib_to_global.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Build global_model.csv (first order only) from a per-transistor
#          variation contribution table exported by the characterization tool,
#          when the signed sensitivities themselves are not available.
#
#   Input CSV columns (one row per point / transistor / param):
#     cell,arc,meas,slew_idx,load_idx,slew,load,v0,sigma_local,inst,group,param,
#     contrib_frac,sigma_mm[,sign]
#   contrib_frac = share of the LVF variance:  (S1*sigma_mm)^2 / sigma_local^2
#   Reconstruction:
#     |S1| = sqrt(contrib_frac) * sigma_local / sigma_mm
#     sign : column "sign" when present, otherwise the pull rule
#            cfg(pull,<group>) = output edge driven by the group (N fall, P rise)
#            vth: +1 when arc out_dir == pull(group) else -1;  u0: opposite
#     g1[g,q] = sum_{i in g} sign_i * |S1_i|          (h2 left empty -> lin/loglin)
# Usage  :
#   tclsh contrib_to_global.tcl -cfg example.cfg.tcl -contrib tool_contrib.csv -o out/global_model_from_contrib.csv
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

proc rule_sign {cell arc group param} {
    set a [::lvfgv::get_arc $cell $arc]
    set od [dict get $a out_dir]
    set pull fall
    if {[info exists ::lvfgv::cfg(pull,$group)]} { set pull $::lvfgv::cfg(pull,$group) }
    set s [expr {$od eq $pull ? 1 : -1}]
    if {$param eq "u0"} { set s [expr {-$s}] }
    return $s
}

proc main {argv} {
    set opt [::lvfgv::parse_args $argv {cfg contrib o} {}]
    foreach k {cfg contrib o} {
        if {![dict exists $opt $k]} {
            puts stderr "usage: tclsh contrib_to_global.tcl -cfg <cfg> -contrib <contrib.csv> -o <global_model.csv>"
            exit 1
        }
    }
    ::lvfgv::load_cfg [dict get $opt cfg]
    lassign [::lvfgv::csv_read [dict get $opt contrib]] hdr rows
    set g1 [dict create]
    set ntr [dict create]
    set info [dict create]
    set order {}
    set nrule 0
    foreach r $rows {
        set key [join [list [dict get $r cell] [dict get $r arc] [dict get $r meas] [dict get $r slew_idx] [dict get $r load_idx]] \t]
        set gp "[dict get $r group],[dict get $r param]"
        if {![dict exists $info $key]} {
            lappend order $key
            dict set info $key [list [dict get $r slew] [dict get $r load] [dict get $r v0]]
        }
        set frac [dict get $r contrib_frac]
        set sl   [dict get $r sigma_local]
        set sm   [dict get $r sigma_mm]
        if {$frac eq "" || $sl eq "" || $sm eq "" || $sm == 0} { continue }
        set mag [expr {sqrt(abs($frac)) * $sl / $sm}]
        if {[dict exists $r sign] && [dict get $r sign] ne ""} {
            set sg [dict get $r sign]
        } else {
            set sg [rule_sign [dict get $r cell] [dict get $r arc] [dict get $r group] [dict get $r param]]
            incr nrule
        }
        dict set g1 "$key\t$gp" [expr {([dict exists $g1 "$key\t$gp"] ? [dict get $g1 "$key\t$gp"] : 0.0) + $sg * $mag}]
        dict incr ntr "$key\t$gp"
    }
    set out {}
    foreach key $order {
        lassign [split $key \t] cell arc meas j k
        lassign [dict get $info $key] slew load v0
        foreach gp [lsort [dict keys $g1 "$key\t*"]] {
            set gpn [lindex [split $gp \t] end]
            lassign [split $gpn ,] grp p
            lappend out [list $cell $arc $meas $j $k $slew $load $v0 $grp $p [dict get $ntr $gp] \
                [::lvfgv::fnum [dict get $g1 $gp]] "" "" ""]
        }
    }
    ::lvfgv::csv_write [dict get $opt o] {cell arc meas slew_idx load_idx slew load v0 group param ntr g1 h2 g1_direct h2_direct} $out
    ::lvfgv::msg "wrote [dict get $opt o] ([llength $out] rows), sign from rule for $nrule transistor rows"
}
main $argv
