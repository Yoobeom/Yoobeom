#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : build_global_model.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Build the global-variation sensitivity model from the per-transistor
#          sensitivities of the LVF characterization (sens.csv).
#
#   For every (cell, arc, measure, table point) and every variation group g
#   (N, P, ...) and parameter q (vth, u0, ...):
#       g1[g,q] = sum_{i in g} S1[i,q]        first-order global sensitivity
#       h2[g,q] = sum_{i in g} S2[i,q]        second-order (diagonal only)
#   Global shift moves all transistors of a group together, so the coherent
#   sum applies.  Local (mismatch) variation is the RSS of the same terms:
#       sigma_local^2 = sum_i sum_q (S1[i,q] * sigma_mm[i,q])^2
#   Contribution of transistor i: c[i,q] = S1[i,q]*sigma_mm[i,q]
#       contrib_frac = c^2 / sigma_local^2   (LVF variance share)
#       share_global = S1[i,q] / g1[g,q]     (share of the global shift)
#
# Outputs:
#   global_model.csv : cell,arc,meas,slew_idx,load_idx,slew,load,v0,group,param,
#                      ntr,g1,h2,g1_direct,h2_direct
#   local_sigma.csv  : per point sigma_local (and per param split)
#   contrib.csv      : per transistor contribution table
#   contrib_summary.txt : per arc contribution averaged over the table
# Usage  :
#   tclsh build_global_model.tcl -cfg example.cfg.tcl -sens out/sens.csv -o out
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

proc main {argv} {
    set opt [::lvfgv::parse_args $argv {cfg sens o} {}]
    if {![dict exists $opt cfg] || ![dict exists $opt sens]} {
        puts stderr "usage: tclsh build_global_model.tcl -cfg <cfg.tcl> -sens <sens.csv> \[-o <out dir>\]"
        exit 1
    }
    ::lvfgv::load_cfg [dict get $opt cfg]
    set outdir $::lvfgv::cfg(out_dir)
    if {[dict exists $opt o]} { set outdir [file normalize [dict get $opt o]] }
    file mkdir $outdir

    lassign [::lvfgv::csv_read [dict get $opt sens]] hdr rows
    ::lvfgv::msg "read [llength $rows] sensitivity rows"

    # group rows per point
    set pts [dict create]      ;# key -> list of rows
    set order {}
    set nskip 0
    foreach r $rows {
        set key [join [list [dict get $r cell] [dict get $r arc] [dict get $r meas] \
                     [dict get $r slew_idx] [dict get $r load_idx]] \t]
        if {![dict exists $pts $key]} { lappend order $key }
        dict lappend pts $key $r
    }

    set model_rows {}
    set sigma_rows {}
    set contrib_rows {}
    foreach key $order {
        lassign [split $key \t] cell arc meas j k
        set prow [lindex [dict get $pts $key] 0]
        set slew [dict get $prow slew]
        set load [dict get $prow load]
        set v0   [dict get $prow v0]
        # accumulate
        set g1 [dict create]; set h2 [dict create]; set ntr [dict create]
        set g1d [dict create]; set h2d [dict create]
        set var_tot 0.0
        set var_p [dict create]
        set gp_seen {}
        set trrows {}
        foreach r [dict get $pts $key] {
            set inst [dict get $r inst]
            set grp  [dict get $r group]
            set p    [dict get $r param]
            set s1   [dict get $r s1]
            set s2   [dict get $r s2]
            set gp "$grp,$p"
            if {$gp ni $gp_seen} { lappend gp_seen $gp }
            if {[string match "GROUP:*" $inst]} {
                if {$s1 ne ""} { dict set g1d $gp $s1 }
                if {$s2 ne ""} { dict set h2d $gp $s2 }
                continue
            }
            if {$s1 eq "" || $s2 eq ""} { incr nskip; continue }
            dict incr ntr $gp
            dict set g1 $gp [expr {([dict exists $g1 $gp] ? [dict get $g1 $gp] : 0.0) + $s1}]
            dict set h2 $gp [expr {([dict exists $h2 $gp] ? [dict get $h2 $gp] : 0.0) + $s2}]
            set sm [dict get $r sigma_mm]
            if {$sm ne ""} {
                set c [expr {$s1 * $sm}]
                set var_tot [expr {$var_tot + $c*$c}]
                dict set var_p $p [expr {([dict exists $var_p $p] ? [dict get $var_p $p] : 0.0) + $c*$c}]
                lappend trrows [list $inst $grp $p $s1 $sm $c]
            } else {
                lappend trrows [list $inst $grp $p $s1 "" ""]
            }
        }
        foreach gp $gp_seen {
            lassign [split $gp ,] grp p
            if {![dict exists $g1 $gp]} { continue }
            set d1 ""; set d2 ""
            if {[dict exists $g1d $gp]} { set d1 [dict get $g1d $gp] }
            if {[dict exists $h2d $gp]} { set d2 [dict get $h2d $gp] }
            lappend model_rows [list $cell $arc $meas $j $k $slew $load $v0 $grp $p [dict get $ntr $gp] \
                [::lvfgv::fnum [dict get $g1 $gp]] [::lvfgv::fnum [dict get $h2 $gp]] $d1 $d2]
        }
        set sig [expr {sqrt($var_tot)}]
        set sigrel ""
        if {$v0 ne "" && $v0 != 0} { set sigrel [::lvfgv::fnum [expr {$sig / $v0}]] }
        set sp {}
        foreach p $::lvfgv::cfg(params) {
            set vp 0.0
            if {[dict exists $var_p $p]} { set vp [dict get $var_p $p] }
            lappend sp [::lvfgv::fnum [expr {sqrt($vp)}]]
        }
        lappend sigma_rows [concat [list $cell $arc $meas $j $k $slew $load $v0 [::lvfgv::fnum $sig] $sigrel] $sp]
        foreach tr $trrows {
            lassign $tr inst grp p s1 sm c
            set frac ""; set share ""; set c1g ""
            if {$c ne "" && $var_tot > 0} { set frac [::lvfgv::fnum [expr {$c*$c / $var_tot}]] }
            if {[dict exists $g1 "$grp,$p"] && [dict get $g1 "$grp,$p"] != 0} {
                set share [::lvfgv::fnum [expr {$s1 / [dict get $g1 "$grp,$p"]}]]
            }
            if {[info exists ::lvfgv::cfg(sigma_g,$grp,$p)]} {
                set c1g [::lvfgv::fnum [expr {$s1 * $::lvfgv::cfg(sigma_g,$grp,$p)}]]
            }
            lappend contrib_rows [list $cell $arc $meas $j $k $inst $grp $p $s1 $sm \
                [expr {$c eq "" ? "" : [::lvfgv::fnum $c]}] $frac $share $c1g]
        }
    }
    if {$nskip > 0} { ::lvfgv::msg "WARNING: $nskip transistor rows without sensitivity were skipped" }

    # per-arc contribution summary (delay rows, averaged over the table)
    set acc [dict create]
    set aorder {}
    foreach c $contrib_rows {
        lassign $c cell arc meas j k inst grp p s1 sm cl frac share c1g
        if {$meas ne "delay" || $share eq ""} { continue }
        set key "$cell\t$arc\t$grp\t$p\t$inst"
        if {![dict exists $acc $key]} { lappend aorder $key; dict set acc $key {} }
        dict lappend acc $key [list $share [expr {$frac eq "" ? 0.0 : $frac}]]
    }
    set txt {}
    lappend txt "Per-transistor contribution, delay arcs, averaged over the table points"
    lappend txt "  share_global = S1_i / sum_{i in group} S1_i   (share of the global shift of the group/param)"
    lappend txt "  lvf_share    = (S1_i*sigma_mm_i)^2 / sigma_local^2   (share of the LVF variance, all groups/params)"
    lappend txt [format "  %-10s %-10s %-6s %-6s %-8s %12s %10s" cell arc group param inst share_global lvf_share]
    foreach key $aorder {
        lassign [split $key \t] cell arc grp p inst
        set sh {}; set fr {}
        foreach e [dict get $acc $key] { lappend sh [lindex $e 0]; lappend fr [lindex $e 1] }
        lappend txt [format "  %-10s %-10s %-6s %-6s %-8s %12.3f %10.3f" $cell $arc $grp $p $inst [::lvfgv::lmean $sh] [::lvfgv::lmean $fr]]
    }
    set fh [open [file join $outdir contrib_summary.txt] w]
    puts $fh [join $txt \n]
    close $fh
    set mh {cell arc meas slew_idx load_idx slew load v0 group param ntr g1 h2 g1_direct h2_direct}
    set sh [concat {cell arc meas slew_idx load_idx slew load v0 sigma_local sigma_local_rel} \
                [lmap p $::lvfgv::cfg(params) {string cat sigma_ $p}]]
    set ch {cell arc meas slew_idx load_idx inst group param s1 sigma_mm c_local contrib_frac share_global c_global_1sig}
    ::lvfgv::csv_write [file join $outdir global_model.csv] $mh $model_rows
    ::lvfgv::csv_write [file join $outdir local_sigma.csv] $sh $sigma_rows
    ::lvfgv::csv_write [file join $outdir contrib.csv] $ch $contrib_rows
    ::lvfgv::msg "wrote $outdir/global_model.csv ([llength $model_rows] rows), local_sigma.csv, contrib.csv, contrib_summary.txt"
}
main $argv
