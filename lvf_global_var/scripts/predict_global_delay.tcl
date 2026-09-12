#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : predict_global_delay.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Evaluate the global-variation sensitivity model (global_model.csv)
#          at a global corner and write the predicted delay / transition
#          tables and per-cell derate factors.
#
#   Model variants (D = shift of group/param, x = g1/v0, y = h2/v0 - x^2):
#     lin     : dv = sum g1*D
#     quad    : dv = sum (g1*D + 0.5*h2*D^2)
#     loglin  : dv = v0*(exp(sum x*D) - 1)
#     logquad : dv = v0*(exp(sum (x*D + 0.5*y*D^2)) - 1)
#   -h2 sum    : h2 = sum of per-transistor second derivatives (default)
#   -h2 direct : h2 from the whole-group +/-delta simulation when available
#
# Outputs:
#   pred_<corner>.csv        : all variants + selected v_pred per table point
#   derate_<corner>.csv      : per cell  ratio statistics (delay rows)
#   derate_<corner>_arcs.csv : per arc   ratio statistics (delay rows)
# Usage  :
#   tclsh predict_global_delay.tcl -cfg example.cfg.tcl -model out/global_model.csv \
#         -corner corners.tcl -name SSG [-mode logquad] [-h2 sum] [-o out]
#   ad-hoc shift: -shift {N vth abs 0.045 P vth abs 0.045} -name MYPT
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

proc stats {vals} {
    return [list [llength $vals] [::lvfgv::fnum [::lvfgv::lmean $vals] %.6f] \
        [::lvfgv::fnum [::lvfgv::lmin $vals] %.6f] [::lvfgv::fnum [::lvfgv::lmax $vals] %.6f]]
}

proc main {argv} {
    set opt [::lvfgv::parse_args $argv {cfg model corner name shift mode h2 o} {}]
    foreach k {cfg model name} {
        if {![dict exists $opt $k]} {
            puts stderr "usage: tclsh predict_global_delay.tcl -cfg <cfg.tcl> -model <global_model.csv> -name <corner>"
            puts stderr "         (-corner <corners.tcl> | -shift {grp param unit val ...}) \[-mode lin|quad|loglin|logquad\] \[-h2 sum|direct\] \[-o <dir>\]"
            exit 1
        }
    }
    ::lvfgv::load_cfg [dict get $opt cfg]
    set outdir $::lvfgv::cfg(out_dir)
    if {[dict exists $opt o]} { set outdir [file normalize [dict get $opt o]] }
    file mkdir $outdir
    set name [dict get $opt name]
    set mode logquad
    if {[dict exists $opt mode]} { set mode [dict get $opt mode] }
    if {$mode ni {lin quad loglin logquad}} { ::lvfgv::die "-mode must be lin|quad|loglin|logquad" }
    set h2sel sum
    if {[dict exists $opt h2]} { set h2sel [dict get $opt h2] }
    if {$h2sel ni {sum direct}} { ::lvfgv::die "-h2 must be sum|direct" }

    if {[dict exists $opt shift]} {
        set entries {}
        foreach {g p u v} [dict get $opt shift] { lappend entries [list $g $p $u $v] }
        set ::lvfgv::corner($name) $entries
    } elseif {[dict exists $opt corner]} {
        ::lvfgv::load_corners [dict get $opt corner]
    } else {
        ::lvfgv::die "need -corner <file> or -shift {...}"
    }
    set shifts [::lvfgv::corner_shifts $name]
    ::lvfgv::msg "corner $name: [join [lmap {k v} $shifts {string cat $k = [format %.4g $v]}] {, }]"

    lassign [::lvfgv::csv_read [dict get $opt model]] hdr rows
    set pts [dict create]
    set order {}
    foreach r $rows {
        set key [join [list [dict get $r cell] [dict get $r arc] [dict get $r meas] \
                     [dict get $r slew_idx] [dict get $r load_idx]] \t]
        if {![dict exists $pts $key]} { lappend order $key }
        dict lappend pts $key $r
    }
    set nfallback 0
    set pred_rows {}
    set cell_ratio [dict create]
    set arc_ratio  [dict create]
    foreach key $order {
        lassign [split $key \t] cell arc meas j k
        set first [lindex [dict get $pts $key] 0]
        set v0 [dict get $first v0]
        if {$v0 eq "" || $v0 == 0} { continue }
        set lin 0.0; set quad 0.0; set lx 0.0; set lq 0.0
        foreach r [dict get $pts $key] {
            set gp "[dict get $r group],[dict get $r param]"
            if {![dict exists $shifts $gp]} { continue }
            set D  [dict get $shifts $gp]
            set g1 [dict get $r g1]
            set h2 [dict get $r h2]
            if {$h2sel eq "direct"} {
                if {[dict get $r h2_direct] ne ""} { set h2 [dict get $r h2_direct] } else { incr nfallback }
            }
            set x [expr {$g1 / $v0}]
            set y [expr {$h2 / $v0 - $x*$x}]
            set lin  [expr {$lin  + $g1*$D}]
            set quad [expr {$quad + $g1*$D + 0.5*$h2*$D*$D}]
            set lx   [expr {$lx   + $x*$D}]
            set lq   [expr {$lq   + $x*$D + 0.5*$y*$D*$D}]
        }
        set dv_lin     $lin
        set dv_quad    $quad
        set dv_loglin  [expr {$v0 * (exp($lx) - 1.0)}]
        set dv_logquad [expr {$v0 * (exp($lq) - 1.0)}]
        set dv [set dv_$mode]
        set vp [expr {$v0 + $dv}]
        lappend pred_rows [list $cell $arc $meas $j $k [dict get $first slew] [dict get $first load] $v0 $name \
            [::lvfgv::fnum $dv_lin] [::lvfgv::fnum $dv_quad] [::lvfgv::fnum $dv_loglin] [::lvfgv::fnum $dv_logquad] \
            [::lvfgv::fnum $vp] [::lvfgv::fnum $dv] [::lvfgv::fnum [expr {$dv / $v0}]] $mode]
        if {$meas eq "delay"} {
            dict lappend cell_ratio $cell [expr {$vp / $v0}]
            dict lappend arc_ratio "$cell\t$arc" [expr {$vp / $v0}]
        }
    }
    if {$nfallback > 0} { ::lvfgv::msg "note: h2_direct missing for $nfallback terms, sum used" }
    set ph {cell arc meas slew_idx load_idx slew load v0 corner dv_lin dv_quad dv_loglin dv_logquad v_pred dv_pred dv_rel_pred mode}
    ::lvfgv::csv_write [file join $outdir "pred_$name.csv"] $ph $pred_rows
    set drows {}
    dict for {cell vals} $cell_ratio { lappend drows [concat [list $cell $name] [stats $vals]] }
    ::lvfgv::csv_write [file join $outdir "derate_$name.csv"] {cell corner npts r_mean r_min r_max} $drows
    set arows {}
    dict for {ca vals} $arc_ratio { lappend arows [concat [split $ca \t] [list $name] [stats $vals]] }
    ::lvfgv::csv_write [file join $outdir "derate_${name}_arcs.csv"] {cell arc corner npts r_mean r_min r_max} $arows
    ::lvfgv::msg "wrote $outdir/pred_$name.csv ([llength $pred_rows] rows), derate_$name.csv, derate_${name}_arcs.csv"
    foreach r $drows {
        ::lvfgv::msg [format "  %-12s delay ratio mean %s  min %s  max %s" [lindex $r 0] [lindex $r 3] [lindex $r 4] [lindex $r 5]]
    }
}
main $argv
