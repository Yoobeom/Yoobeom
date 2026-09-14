# ---------------------------------------------------------------------------
# File   : pt_apply_global_derate.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Apply the per-cell global-variation delay ratios produced by
#          predict_global_delay.tcl (derate_<corner>.csv) as cell delay
#          derates in PrimeTime or Tempus.  Self-contained (no other file).
#
#   ratio r = D(corner) / D(nominal) per cell, statistics over all delay
#   table points of the cell:
#     -stat bound : late = r_max, early = r_min   (conservative, default)
#     -stat mean  : late = early = r_mean         (centered systematic shift)
#     -stat max   : late = early = r_max
#   Equivalent commands:
#     set_timing_derate -cell_delay -late  <r> [get_lib_cells <lib>/<cell>]
#     set_timing_derate -cell_delay -early <r> [get_lib_cells <lib>/<cell>]
#
# Usage (inside pt_shell / tempus):
#   source pt_apply_global_derate.tcl
#   lvfgv_apply_global_derate -csv derate_SSG.csv [-stat bound] [-lib_pattern *] \
#                             [-early 1] [-late 1] [-dry_run 0]
# ---------------------------------------------------------------------------

proc lvfgv_csv_split {line} {
    set out {}
    set cur ""
    set inq 0
    set n [string length $line]
    for {set i 0} {$i < $n} {incr i} {
        set c [string index $line $i]
        if {$inq} {
            if {$c eq "\""} {
                if {[string index $line [expr {$i+1}]] eq "\""} { append cur "\""; incr i } else { set inq 0 }
            } else { append cur $c }
        } else {
            if {$c eq "\""} { set inq 1 } elseif {$c eq ","} { lappend out $cur; set cur "" } else { append cur $c }
        }
    }
    lappend out $cur
    return $out
}

proc lvfgv_apply_global_derate {args} {
    array set o {-csv "" -stat bound -lib_pattern * -early 1 -late 1 -dry_run 0}
    foreach {k v} $args {
        if {![info exists o($k)]} { error "lvfgv_apply_global_derate: unknown option $k" }
        set o($k) $v
    }
    if {$o(-csv) eq ""} { error "lvfgv_apply_global_derate: -csv <derate_<corner>.csv> is required" }
    if {$o(-stat) ni {bound mean max}} { error "lvfgv_apply_global_derate: -stat must be bound|mean|max" }
    set fh [open $o(-csv) r]
    set header {}
    set nset 0
    set nmiss 0
    set missing {}
    while {[gets $fh line] >= 0} {
        if {[string trim $line] eq "" || [string index $line 0] eq "#"} { continue }
        set f [lvfgv_csv_split $line]
        if {[llength $header] == 0} { set header $f; continue }
        array unset r
        for {set i 0} {$i < [llength $header]} {incr i} { set r([lindex $header $i]) [lindex $f $i] }
        switch -- $o(-stat) {
            bound { set late $r(r_max);  set early $r(r_min) }
            mean  { set late $r(r_mean); set early $r(r_mean) }
            max   { set late $r(r_max);  set early $r(r_max) }
        }
        set pattern "$o(-lib_pattern)/$r(cell)"
        if {$o(-dry_run)} {
            if {$o(-late)}  { puts "set_timing_derate -cell_delay -late  [format %.5f $late]  \[get_lib_cells $pattern\]" }
            if {$o(-early)} { puts "set_timing_derate -cell_delay -early [format %.5f $early] \[get_lib_cells $pattern\]" }
            incr nset
            continue
        }
        set lc [get_lib_cells -quiet $pattern]
        if {[sizeof_collection $lc] == 0} { incr nmiss; lappend missing $r(cell); continue }
        if {$o(-late)}  { set_timing_derate -cell_delay -late  $late  $lc }
        if {$o(-early)} { set_timing_derate -cell_delay -early $early $lc }
        incr nset
    }
    close $fh
    puts "lvfgv_apply_global_derate: corner derate ($o(-stat)) applied to $nset lib cell(s), $nmiss not found"
    if {$nmiss > 0} { puts "  not found: $missing" }
    return $nset
}
