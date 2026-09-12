#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : summarize_validation.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Collect validate_<corner>.csv files of an output directory into one
#          table: per corner and model variant, mean / max error of the delay
#          and transition values (percent of the corner value) and of the shift.
#          With -contrib_check, compare global_model_from_contrib.csv (first
#          order rebuilt from unsigned contributions) with global_model.csv.
# Usage  :
#   tclsh summarize_validation.tcl -out out [-cfg example.cfg.tcl] [-contrib_check]
#   -cfg adds the coherence report (needs cfg(sigma_g,...))
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

proc coherence_report {outdir} {
    # first-order coherent sum vs whole-group perturbation, and cross-term size,
    # both expressed at a 3 sigma_g shift in % of the nominal delay
    set f [file join $outdir global_model.csv]
    if {![file exists $f]} { return }
    lassign [::lvfgv::csv_read $f] h rows
    set e1 [dict create]; set e2 [dict create]; set order {}
    foreach r $rows {
        if {[dict get $r meas] ne "delay" || [dict get $r g1_direct] eq "" || [dict get $r h2_direct] eq ""} { continue }
        set g [dict get $r group]; set p [dict get $r param]
        if {![info exists ::lvfgv::cfg(sigma_g,$g,$p)]} { continue }
        set D [expr {3.0 * $::lvfgv::cfg(sigma_g,$g,$p)}]
        set v0 [dict get $r v0]
        set k "[dict get $r cell]\t$g/$p"
        if {$k ni $order} { lappend order $k }
        dict lappend e1 $k [expr {abs([dict get $r g1] - [dict get $r g1_direct]) * $D / $v0 * 100.0}]
        dict lappend e2 $k [expr {0.5 * ([dict get $r h2_direct] - [dict get $r h2]) * $D * $D / $v0 * 100.0}]
    }
    if {[llength $order] == 0} { return }
    puts ""
    puts "Sensitivity consistency at a 3 sigma_g shift, % of nominal delay (delay rows):"
    puts "  d1 = |sum_i S1_i - S1_group| * 3sg / v0     (first order, must be ~0)"
    puts "  d2 = 0.5 * (H2_group - sum_i S2_i) * (3sg)^2 / v0   (cross terms missing in the per-transistor sum)"
    puts [format "  %-10s %-6s %12s %12s %12s %12s" cell grp/par "mean d1" "max d1" "mean d2" "max|d2|"]
    foreach k $order {
        lassign [split $k \t] cell gp
        set l2 [dict get $e2 $k]
        set m2 0.0
        foreach v $l2 { if {abs($v) > abs($m2)} { set m2 $v } }
        puts [format "  %-10s %-6s %12.3f %12.3f %12.3f %12.3f" $cell $gp [::lvfgv::lmean [dict get $e1 $k]] [::lvfgv::lmax [dict get $e1 $k]] [::lvfgv::lmean $l2] $m2]
    }
}

proc main {argv} {
    set opt [::lvfgv::parse_args $argv {out cfg} {contrib_check}]
    set outdir out
    if {[dict exists $opt out]} { set outdir [dict get $opt out] }
    if {[dict exists $opt cfg]} { ::lvfgv::load_cfg [dict get $opt cfg] }
    set files [lsort [glob -nocomplain [file join $outdir validate_*.csv]]]
    if {[llength $files] == 0} { ::lvfgv::die "no validate_*.csv in $outdir" }
    set variants {lin quad loglin logquad}
    puts "Model error versus direct global-corner simulation"
    puts "  e  : |v_model - v_sim| / v_sim  in %  (delay rows)"
    puts "  es : |dv_model - dv_sim| / |dv_sim| in %  (delay rows, error of the shift itself)"
    puts [format "%-9s %8s %8s | %s" corner "shift%" "npts" [join [lmap v $variants {format "%7s mean/max e   mean es" $v}] " | "]]
    foreach f $files {
        lassign [::lvfgv::csv_read $f] h rows
        set cname [dict get [lindex $rows 0] corner]
        set e [dict create]; set es [dict create]
        set shifts {}
        set n 0
        foreach r $rows {
            if {[dict get $r meas] ne "delay"} { continue }
            incr n
            lappend shifts [expr {[dict get $r dv_sim_rel] * 100.0}]
            foreach v $variants {
                dict lappend e $v [expr {abs([dict get $r err_abs_pct_$v])}]
                set x [dict get $r err_shift_pct_$v]
                if {$x ne ""} { dict lappend es $v [expr {abs($x)}] }
            }
        }
        set cols {}
        foreach v $variants {
            lappend cols [format "%5.2f / %5.2f  %6.1f" [::lvfgv::lmean [dict get $e $v]] [::lvfgv::lmax [dict get $e $v]] [::lvfgv::lmean [dict get $es $v]]]
        }
        puts [format "%-9s %8.1f %8d | %s" $cname [::lvfgv::lmean $shifts] $n [join $cols " | "]]
    }
    if {[dict exists $opt cfg]} { coherence_report $outdir }
    if {[dict get $opt contrib_check]} {
        set fa [file join $outdir global_model.csv]
        set fb [file join $outdir global_model_from_contrib.csv]
        if {[file exists $fa] && [file exists $fb]} {
            lassign [::lvfgv::csv_read $fa] h ra
            lassign [::lvfgv::csv_read $fb] h rb
            set ref [dict create]
            foreach r $ra { dict set ref "[dict get $r cell],[dict get $r arc],[dict get $r meas],[dict get $r slew_idx],[dict get $r load_idx],[dict get $r group],[dict get $r param]" [list [dict get $r g1] [dict get $r v0]] }
            set errs [dict create]
            foreach r $rb {
                set k "[dict get $r cell],[dict get $r arc],[dict get $r meas],[dict get $r slew_idx],[dict get $r load_idx],[dict get $r group],[dict get $r param]"
                if {![dict exists $ref $k] || [dict get $r meas] ne "delay"} { continue }
                set g [dict get $r group]; set p [dict get $r param]
                if {![info exists ::lvfgv::cfg(sigma_g,$g,$p)]} { continue }
                lassign [dict get $ref $k] a v0
                set b [dict get $r g1]
                set D [expr {3.0 * $::lvfgv::cfg(sigma_g,$g,$p)}]
                dict lappend errs "$g,$p" [expr {abs($b - $a) * $D / $v0 * 100.0}]
            }
            puts ""
            puts "First-order term rebuilt from unsigned contributions (pull-rule sign) vs signed sum,"
            puts "error at a 3 sigma_g shift in % of nominal delay (delay rows):"
            foreach k [lsort [dict keys $errs]] {
                puts [format "  %-8s mean %6.3f %%  max %6.3f %%  (n=%d)" $k [::lvfgv::lmean [dict get $errs $k]] [::lvfgv::lmax [dict get $errs $k]] [llength [dict get $errs $k]]]
            }
        }
    }
}
main $argv
