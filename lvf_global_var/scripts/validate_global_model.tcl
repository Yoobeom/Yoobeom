#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : validate_global_model.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Compare the model prediction (pred_<corner>.csv) against the direct
#          global-corner simulation (corner_<corner>.csv) and report the error
#          of every model variant.
#
#   err_shift_pct = (dv_model - dv_sim) / dv_sim * 100   (error of the shift)
#   err_abs_pct   = (dv_model - dv_sim) / v_sim * 100    (error of the value)
# Outputs:
#   validate_<corner>.csv, validate_<corner>.txt (summary)
# Usage  :
#   tclsh validate_global_model.tcl -pred out/pred_SSG.csv -sim out/corner_SSG.csv [-o out] [-tol_pct 2]
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

set variants {lin quad loglin logquad}

proc main {argv} {
    global variants
    set opt [::lvfgv::parse_args $argv {pred sim o tol_pct} {}]
    if {![dict exists $opt pred] || ![dict exists $opt sim]} {
        puts stderr "usage: tclsh validate_global_model.tcl -pred <pred.csv> -sim <corner.csv> \[-o <dir>\] \[-tol_pct 2\]"
        exit 1
    }
    set tol 2.0
    if {[dict exists $opt tol_pct]} { set tol [dict get $opt tol_pct] }
    lassign [::lvfgv::csv_read [dict get $opt pred]] ph prows
    lassign [::lvfgv::csv_read [dict get $opt sim]]  sh srows
    set outdir [file dirname [file normalize [dict get $opt pred]]]
    if {[dict exists $opt o]} { set outdir [file normalize [dict get $opt o]] }
    file mkdir $outdir
    set sim [dict create]
    set cname ""
    foreach r $srows {
        set key [join [list [dict get $r cell] [dict get $r arc] [dict get $r meas] [dict get $r slew_idx] [dict get $r load_idx]] \t]
        dict set sim $key $r
        set cname [dict get $r corner]
    }
    set out {}
    set err [dict create]     ;# "scope\tvariant\tmetric" -> list
    set nviol [dict create]
    set mode ""
    foreach r $prows {
        set key [join [list [dict get $r cell] [dict get $r arc] [dict get $r meas] [dict get $r slew_idx] [dict get $r load_idx]] \t]
        if {![dict exists $sim $key]} { continue }
        set s [dict get $sim $key]
        set v0 [dict get $s v0]; set vs [dict get $s v_sim]
        if {$v0 eq "" || $vs eq ""} { continue }
        set dvs [expr {$vs - $v0}]
        set mode [dict get $r mode]
        set row [list [dict get $r cell] [dict get $r arc] [dict get $r meas] [dict get $r slew_idx] [dict get $r load_idx] \
                     [dict get $r corner] $v0 $vs [::lvfgv::fnum $dvs] [::lvfgv::fnum [expr {$dvs/$v0}]]]
        foreach v $variants {
            set dvm [dict get $r dv_$v]
            set e_abs [expr {($dvm - $dvs) / $vs * 100.0}]
            set e_shift ""
            if {abs($dvs) > 1e-15} { set e_shift [expr {($dvm - $dvs) / $dvs * 100.0}] }
            lappend row [::lvfgv::fnum $dvm] [format %.3f $e_abs] [expr {$e_shift eq "" ? "" : [format %.2f $e_shift]}]
            foreach scope [list ALL [dict get $r cell] "[dict get $r cell]/[dict get $r meas]" "ALL/[dict get $r meas]"] {
                dict lappend err "$scope\t$v\tabs" [expr {abs($e_abs)}]
                if {$e_shift ne ""} { dict lappend err "$scope\t$v\tshift" [expr {abs($e_shift)}] }
            }
            if {abs($e_abs) > $tol} { dict incr nviol $v }
        }
        lappend out $row
    }
    if {[llength $out] == 0} { ::lvfgv::die "no matching points between prediction and simulation" }
    set hdr {cell arc meas slew_idx load_idx corner v0 v_sim dv_sim dv_sim_rel}
    foreach v $variants { lappend hdr dv_$v err_abs_pct_$v err_shift_pct_$v }
    ::lvfgv::csv_write [file join $outdir "validate_$cname.csv"] $hdr $out

    set txt {}
    lappend txt "corner $cname : [llength $out] points, selected mode = $mode, tolerance = $tol % of value"
    lappend txt [format "%-22s %-8s %8s %8s %10s %10s %6s" scope variant "mean|e|" "max|e|" "mean|es|" "max|es|" "viol"]
    lappend txt "  e  = error in % of the corner value, es = error in % of the simulated shift"
    set scopes {ALL ALL/delay ALL/trans}
    foreach r $out {
        set c [lindex $r 0]
        if {$c ni $scopes} { lappend scopes $c }
    }
    foreach scope $scopes {
        foreach v $variants {
            if {![dict exists $err "$scope\t$v\tabs"]} { continue }
            set ea [dict get $err "$scope\t$v\tabs"]
            set es {}
            if {[dict exists $err "$scope\t$v\tshift"]} { set es [dict get $err "$scope\t$v\tshift"] }
            set nv ""
            if {$scope eq "ALL"} { set nv [expr {[dict exists $nviol $v] ? [dict get $nviol $v] : 0}] }
            lappend txt [format "%-22s %-8s %8.3f %8.3f %10.2f %10.2f %6s" $scope $v \
                [::lvfgv::lmean $ea] [::lvfgv::lmax $ea] \
                [expr {[llength $es] ? [::lvfgv::lmean $es] : 0.0}] [expr {[llength $es] ? [::lvfgv::lmax $es] : 0.0}] $nv]
        }
    }
    set fh [open [file join $outdir "validate_$cname.txt"] w]
    puts $fh [join $txt \n]
    close $fh
    puts [join $txt \n]
}
main $argv
