#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# File   : apply_to_liberty.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Apply the predicted global-variation shift (pred_<corner>.csv) to a
#          Liberty file and write the shifted library.
#
#   For every (cell, arc) of the prediction the matching timing() group is
#   located (pin = arc out, related_pin = arc in, when = arc when, timing_type
#   combinational) and the cell_rise|cell_fall (delay) and
#   rise_transition|fall_transition (trans) values are scaled:
#       v_new = v_old * (1 + r(slew, load))
#   r = dv_rel_pred interpolated (bilinear, clamped) from the model grid onto
#   the Liberty table grid.  Relative scaling keeps the library's own nominal
#   values; the model only supplies the shift.
#   Cells and tables not covered by the prediction are copied unchanged.
#
# Usage  :
#   tclsh apply_to_liberty.tcl -cfg example.cfg.tcl -lib in.lib -pred out/pred_SSG.csv \
#         -o out.lib [-suffix _SSG] [-tables delay|trans|both] [-scale_sigma] [-cells {A B}]
#   -scale_sigma : also scale ocv_sigma_* / ocv_std_dev_* / ocv_mean_shift_* tables
#                  of the same arc by (1 + r) (first-order assumption)
# ---------------------------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lvfgv_common.tcl]

namespace eval ::libp {
    variable text
    variable tokre {/\*(?:[^*]|\*+[^*/])*\*+/|//[^\n]*|"(?:[^"\\]|\\.)*"|\\\r?\n|[{}();:,]|[^\s{}();:,"/]+}
    variable warn 0
}

# ---------------------------------------------------------------------------
# Find the offset of the closing brace matching the opening brace at $start
# (strings and comments skipped).  Returns -1 when not found.
# ---------------------------------------------------------------------------
proc ::libp::match_brace {start} {
    variable text
    set depth 0
    set pos $start
    set re {[{}"]|/\*}
    while {[regexp -indices -start $pos -- $re $text m]} {
        lassign $m s e
        set c [string index $text $s]
        switch -- $c {
            "\{" { incr depth; set pos [expr {$s+1}] }
            "\}" {
                incr depth -1
                if {$depth == 0} { return $s }
                set pos [expr {$s+1}]
            }
            "\"" {
                # skip string (with backslash escapes)
                set p [expr {$s+1}]
                while {1} {
                    set q [string first "\"" $text $p]
                    if {$q < 0} { return -1 }
                    set nb 0
                    set b [expr {$q-1}]
                    while {$b >= $p && [string index $text $b] eq "\\"} { incr nb; incr b -1 }
                    if {$nb % 2 == 0} { break }
                    set p [expr {$q+1}]
                }
                set pos [expr {$q+1}]
            }
            default {
                set q [string first "*/" $text [expr {$s+2}]]
                if {$q < 0} { return -1 }
                set pos [expr {$q+2}]
            }
        }
    }
    return -1
}

# ---------------------------------------------------------------------------
# Tokenize text range [s,e] -> list of {type text start end}
# ---------------------------------------------------------------------------
proc ::libp::tokenize {s e} {
    variable text
    variable tokre
    set toks {}
    set sub [string range $text $s $e]
    foreach m [regexp -all -inline -indices -- $tokre $sub] {
        lassign $m a b
        set t [string range $sub $a $b]
        set c [string index $t 0]
        if {$c eq "/" || $c eq "\\"} { continue }
        if {$c eq "\""} {
            set type str
        } elseif {[string first $c "{}();:,"] >= 0} {
            set type $c
        } else {
            set type word
        }
        lappend toks [list $type $t [expr {$s+$a}] [expr {$s+$b}]]
    }
    return $toks
}

proc ::libp::unquote {s} {
    if {[string length $s] >= 2 && [string index $s 0] eq "\"" && [string index $s end] eq "\""} {
        return [string range $s 1 end-1]
    }
    return $s
}

# ---------------------------------------------------------------------------
# Parse a token list into items (recursive).  iVar is the token index.
#   item: kind attr  name value
#         kind cattr name args astart aend      (offsets of '(' and ')')
#         kind group name args items
# ---------------------------------------------------------------------------
proc ::libp::parse_items {toks iVar} {
    upvar $iVar i
    set n [llength $toks]
    set items {}
    while {$i < $n} {
        lassign [lindex $toks $i] type t
        if {$type eq "\}"} { incr i; return $items }
        if {$type ne "word"} { incr i; continue }
        set name $t
        incr i
        if {$i >= $n} { break }
        lassign [lindex $toks $i] type2 t2
        if {$type2 eq ":"} {
            incr i
            set val {}
            while {$i < $n && [lindex $toks $i 0] ne ";"} {
                lappend val [lindex $toks $i 1]
                incr i
            }
            incr i
            lappend items [dict create kind attr name $name value [join $val " "]]
        } elseif {$type2 eq "("} {
            set astart [lindex $toks $i 2]
            incr i
            set args {}
            while {$i < $n && [lindex $toks $i 0] ne ")"} {
                set tk [lindex $toks $i]
                if {[lindex $tk 0] in {str word}} { lappend args [unquote [lindex $tk 1]] }
                incr i
            }
            set aend [lindex $toks $i 3]
            incr i
            if {$i < $n && [lindex $toks $i 0] eq "\{"} {
                incr i
                set sub [parse_items $toks i]
                lappend items [dict create kind group name $name args $args items $sub]
            } else {
                if {$i < $n && [lindex $toks $i 0] eq ";"} { incr i }
                lappend items [dict create kind cattr name $name args $args astart $astart aend $aend]
            }
        } else {
            # unknown construct, skip token
        }
    }
    return $items
}

proc ::libp::get_attr {items name} {
    foreach it $items {
        if {[dict get $it kind] eq "attr" && [dict get $it name] eq $name} { return [unquote [dict get $it value]] }
    }
    return ""
}
proc ::libp::get_cattr {items name} {
    foreach it $items {
        if {[dict get $it kind] eq "cattr" && [dict get $it name] eq $name} { return $it }
    }
    return ""
}
proc ::libp::get_groups {items name} {
    set out {}
    foreach it $items {
        if {[dict get $it kind] eq "group" && [dict get $it name] eq $name} { lappend out $it }
    }
    return $out
}

proc ::libp::num_list {s} {
    set out {}
    foreach v [split [string map {, " "} $s] " "] {
        if {$v ne ""} { lappend out [expr {double($v)}] }
    }
    return $out
}

# ---------------------------------------------------------------------------
# Library units and templates
# ---------------------------------------------------------------------------
proc ::libp::unit_scale {num unit} {
    set unit [string tolower $unit]
    set u [string range $unit 0 end-1]
    switch -- $unit {
        s - f { set sc 1.0 }
        default {
            switch -- [string index $unit 0] {
                m { set sc 1e-3 } u { set sc 1e-6 } n { set sc 1e-9 } p { set sc 1e-12 } f { set sc 1e-15 }
                default { ::lvfgv::die "unknown unit: $unit" }
            }
        }
    }
    return [expr {double($num) * $sc}]
}

proc ::libp::read_header {} {
    variable text
    variable tscale
    variable cscale
    variable templates
    set tscale 1e-9
    set cscale 1e-12
    if {[regexp {time_unit\s*:\s*"?\s*([0-9.]+)\s*([a-zA-Z]+)\s*"?\s*;} $text -> n u]} { set tscale [unit_scale $n $u] }
    if {[regexp {capacitive_load_unit\s*\(\s*([0-9.]+)\s*,\s*"?\s*([a-zA-Z]+)\s*"?\s*\)} $text -> n u]} { set cscale [unit_scale $n $u] }
    ::lvfgv::msg "library units: time [format %g $tscale] s, capacitance [format %g $cscale] F"
    set templates [dict create]
    set pos 0
    while {[regexp -indices -start $pos -- {\mlu_table_template\s*\(\s*"?([^")\s]+)"?\s*\)\s*\{} $text m nm]} {
        set name [string range $text {*}$nm]
        set ob [lindex $m 1]
        set cb [match_brace $ob]
        if {$cb < 0} { ::lvfgv::die "unbalanced braces in template $name" }
        set toks [tokenize [expr {$ob+1}] [expr {$cb-1}]]
        set i 0
        set items [parse_items $toks i]
        set d [dict create]
        foreach k {variable_1 variable_2} { dict set d $k [get_attr $items $k] }
        foreach k {index_1 index_2} {
            set ca [get_cattr $items $k]
            dict set d $k [expr {$ca eq "" ? "" : [num_list [lindex [dict get $ca args] 0]]}]
        }
        dict set templates $name $d
        set pos [expr {$cb+1}]
    }
    ::lvfgv::msg "[dict size $templates] lu_table_template(s) read"
}

# ---------------------------------------------------------------------------
# Bilinear interpolation with clamping on a grid xs (sorted) x ys (sorted)
#   grid: dict "i,j" -> value
# ---------------------------------------------------------------------------
proc ::libp::bracket {xs x} {
    set n [llength $xs]
    if {$x <= [lindex $xs 0]} { return [list 0 0 0.0] }
    if {$x >= [lindex $xs end]} { return [list [expr {$n-1}] [expr {$n-1}] 0.0] }
    for {set i 0} {$i < $n-1} {incr i} {
        set a [lindex $xs $i]; set b [lindex $xs [expr {$i+1}]]
        if {$x >= $a && $x <= $b} {
            set f [expr {$b > $a ? ($x-$a)/($b-$a) : 0.0}]
            return [list $i [expr {$i+1}] $f]
        }
    }
    return [list [expr {$n-1}] [expr {$n-1}] 0.0]
}
proc ::libp::interp2 {xs ys grid x y} {
    lassign [bracket $xs $x] i0 i1 fx
    lassign [bracket $ys $y] j0 j1 fy
    set v00 [dict get $grid "$i0,$j0"]; set v10 [dict get $grid "$i1,$j0"]
    set v01 [dict get $grid "$i0,$j1"]; set v11 [dict get $grid "$i1,$j1"]
    set v0 [expr {$v00 + ($v10-$v00)*$fx}]
    set v1 [expr {$v01 + ($v11-$v01)*$fx}]
    return [expr {$v0 + ($v1-$v0)*$fy}]
}

# ---------------------------------------------------------------------------
# Table patch: returns replacement {astart aend newtext} or "" when skipped
#   tbl: group item, model: dict {xs ys grid} (xs slews [s], ys loads [F])
# ---------------------------------------------------------------------------
proc ::libp::patch_table {tbl model ctx} {
    variable text
    variable templates
    variable tscale
    variable cscale
    variable warn
    set items [dict get $tbl items]
    set tname [lindex [dict get $tbl args] 0]
    set tdef [dict create variable_1 "" variable_2 "" index_1 "" index_2 ""]
    if {[dict exists $templates $tname]} { set tdef [dict get $templates $tname] }
    set idx1 [dict get $tdef index_1]; set idx2 [dict get $tdef index_2]
    foreach k {index_1 index_2} {
        set ca [get_cattr $items $k]
        if {$ca ne ""} { set [string map {index_ idx} $k] [num_list [lindex [dict get $ca args] 0]] }
    }
    set var1 [dict get $tdef variable_1]; set var2 [dict get $tdef variable_2]
    set vca [get_cattr $items values]
    if {$vca eq ""} { return "" }
    if {[llength $idx1] == 0 || [llength $idx2] == 0 || $var1 eq "" || $var2 eq ""} {
        ::lvfgv::msg "WARNING: $ctx: table [dict get $tbl name] ($tname) is not a 2-D slew x load table, skipped"
        incr warn
        return ""
    }
    if {$var1 eq "input_net_transition" && $var2 eq "total_output_net_capacitance"} {
        set order sl
    } elseif {$var1 eq "total_output_net_capacitance" && $var2 eq "input_net_transition"} {
        set order ls
    } else {
        ::lvfgv::msg "WARNING: $ctx: template $tname variables ($var1,$var2) not supported, skipped"
        incr warn
        return ""
    }
    set rows {}
    foreach a [dict get $vca args] { lappend rows [num_list $a] }
    if {[llength $rows] != [llength $idx1]} {
        ::lvfgv::msg "WARNING: $ctx: values rows ([llength $rows]) != index_1 size ([llength $idx1]), skipped"
        incr warn
        return ""
    }
    set xs [dict get $model xs]; set ys [dict get $model ys]; set grid [dict get $model grid]
    set newrows {}
    set rmin 1e9; set rmax -1e9
    for {set i 0} {$i < [llength $idx1]} {incr i} {
        set row [lindex $rows $i]
        if {[llength $row] != [llength $idx2]} {
            ::lvfgv::msg "WARNING: $ctx: values row $i size != index_2 size, skipped"
            incr warn
            return ""
        }
        set nr {}
        for {set j 0} {$j < [llength $idx2]} {incr j} {
            if {$order eq "sl"} {
                set slew [expr {[lindex $idx1 $i] * $tscale}]; set load [expr {[lindex $idx2 $j] * $cscale}]
            } else {
                set load [expr {[lindex $idx1 $i] * $cscale}]; set slew [expr {[lindex $idx2 $j] * $tscale}]
            }
            set r [interp2 $xs $ys $grid $slew $load]
            if {$r < $rmin} { set rmin $r }
            if {$r > $rmax} { set rmax $r }
            lappend nr [format %.6g [expr {[lindex $row $j] * (1.0 + $r)}]]
        }
        lappend newrows $nr
    }
    # indentation of the values line
    set ls [string last "\n" $text [dict get $vca astart]]
    set indent ""
    regexp {^\s*} [string range $text [expr {$ls+1}] [dict get $vca astart]] indent
    set nt "( \\\n"
    for {set i 0} {$i < [llength $newrows]} {incr i} {
        set sep [expr {$i < [llength $newrows]-1 ? "," : ""}]
        append nt "${indent}  \"[join [lindex $newrows $i] {, }]\"$sep \\\n"
    }
    append nt "${indent})"
    return [list [dict get $vca astart] [dict get $vca aend] $nt [format "%.4f..%.4f" $rmin $rmax]]
}

proc ::libp::norm_when {w} {
    set w [unquote [string trim $w]]
    regsub -all {\s+} $w {} w
    return $w
}

# ---------------------------------------------------------------------------
proc main {argv} {
    set opt [::lvfgv::parse_args $argv {cfg lib pred o suffix tables cells} {scale_sigma}]
    foreach k {cfg lib pred o} {
        if {![dict exists $opt $k]} {
            puts stderr "usage: tclsh apply_to_liberty.tcl -cfg <cfg> -lib <in.lib> -pred <pred.csv> -o <out.lib>"
            puts stderr "         \[-suffix _SSG\] \[-tables delay|trans|both\] \[-scale_sigma\] \[-cells {..}\]"
            exit 1
        }
    }
    ::lvfgv::load_cfg [dict get $opt cfg]
    set tables both
    if {[dict exists $opt tables]} { set tables [dict get $opt tables] }
    set meas_list [expr {$tables eq "both" ? {delay trans} : [list $tables]}]
    set fh [open [dict get $opt lib] r]
    set ::libp::text [read $fh]
    close $fh
    ::lvfgv::msg "read [dict get $opt lib] ([string length $::libp::text] bytes)"
    ::libp::read_header

    # prediction -> model grids per cell,arc,meas
    lassign [::lvfgv::csv_read [dict get $opt pred]] ph prows
    set models [dict create]
    set cname ""
    foreach r $prows {
        set key "[dict get $r cell]\t[dict get $r arc]\t[dict get $r meas]"
        set cname [dict get $r corner]
        dict set models $key pts [dict get $r slew_idx],[dict get $r load_idx] \
            [list [dict get $r slew] [dict get $r load] [dict get $r dv_rel_pred]]
    }
    set cells_pred {}
    dict for {key d} $models {
        set xs {}; set ys {}; set grid [dict create]
        dict for {ij v} [dict get $d pts] {
            lassign [split $ij ,] i j
            lassign $v s l r
            dict set grid "$i,$j" $r
            dict set xs $i [expr {double($s)}]
            dict set ys $j [expr {double($l)}]
        }
        set xl {}; foreach i [lsort -integer [dict keys $xs]] { lappend xl [dict get $xs $i] }
        set yl {}; foreach j [lsort -integer [dict keys $ys]] { lappend yl [dict get $ys $j] }
        dict set models $key xs $xl
        dict set models $key ys $yl
        dict set models $key grid $grid
        set c [lindex [split $key \t] 0]
        if {$c ni $cells_pred} { lappend cells_pred $c }
    }
    if {[dict exists $opt cells]} {
        set cells_pred [lmap c $cells_pred {expr {$c in [dict get $opt cells] ? $c : [continue]}}]
    }
    ::lvfgv::msg "prediction $cname covers [llength $cells_pred] cell(s)"

    # walk cells
    set repl {}
    set npatch 0
    set pos 0
    set found {}
    while {[regexp -indices -start $pos -- {\mcell\s*\(\s*"?([^")\s]+)"?\s*\)\s*\{} $::libp::text m nm]} {
        set cell [string range $::libp::text {*}$nm]
        set ob [lindex $m 1]
        set cb [::libp::match_brace $ob]
        if {$cb < 0} { ::lvfgv::die "unbalanced braces in cell $cell" }
        set pos [expr {$cb+1}]
        if {$cell ni $cells_pred} { continue }
        lappend found $cell
        set toks [::libp::tokenize [expr {$ob+1}] [expr {$cb-1}]]
        set i 0
        set items [::libp::parse_items $toks i]
        foreach arc $::lvfgv::cfg(arcs,$cell) {
            set an  [dict get $arc name]
            set od  [dict get $arc out_dir]
            set awhen ""
            if {[dict exists $arc when]} { set awhen [::libp::norm_when [dict get $arc when]] }
            set nmatch 0
            foreach pin [::libp::get_groups $items pin] {
                if {![string equal -nocase [lindex [dict get $pin args] 0] [dict get $arc out]]} { continue }
                foreach tg [::libp::get_groups [dict get $pin items] timing] {
                    set ti [dict get $tg items]
                    set rp [::libp::get_attr $ti related_pin]
                    if {![string equal -nocase [string trim $rp] [dict get $arc in]]} { continue }
                    set tt [::libp::get_attr $ti timing_type]
                    if {$tt ne "" && ![string match combinational* $tt]} { continue }
                    if {[::libp::norm_when [::libp::get_attr $ti when]] ne $awhen} { continue }
                    incr nmatch
                    foreach meas $meas_list {
                        set key "$cell\t$an\t$meas"
                        if {![dict exists $models $key]} { continue }
                        set tnames [expr {$meas eq "delay" ? [list cell_$od] : [list ${od}_transition]}]
                        if {[dict get $opt scale_sigma]} {
                            if {$meas eq "delay"} {
                                lappend tnames ocv_sigma_cell_$od ocv_std_dev_cell_$od ocv_mean_shift_cell_$od
                            } else {
                                lappend tnames ocv_sigma_${od}_transition ocv_std_dev_${od}_transition ocv_mean_shift_${od}_transition
                            }
                        }
                        foreach tn $tnames {
                            foreach tbl [::libp::get_groups $ti $tn] {
                                set rp [::libp::patch_table $tbl [dict get $models $key] "$cell/$an/$tn"]
                                if {$rp ne ""} {
                                    lappend repl $rp
                                    incr npatch
                                    ::lvfgv::msg "  $cell $an $tn : scale 1+r, r = [lindex $rp 3]"
                                }
                            }
                        }
                    }
                }
            }
            if {$nmatch == 0} {
                ::lvfgv::msg "WARNING: $cell arc $an: no matching timing() group (pin [dict get $arc out], related_pin [dict get $arc in], when \"$awhen\")"
                incr ::libp::warn
            }
        }
    }
    foreach c $cells_pred {
        if {$c ni $found} { ::lvfgv::msg "WARNING: cell $c of the prediction not found in the library"; incr ::libp::warn }
    }
    # library name suffix + comment
    if {[dict exists $opt suffix]} {
        if {[regexp -indices -- {\mlibrary\s*\(\s*"?([^")\s]+)"?\s*\)} $::libp::text m nm]} {
            set old [string range $::libp::text {*}$nm]
            lappend repl [list [lindex $nm 0] [lindex $nm 1] "$old[dict get $opt suffix]" ""]
            set lb [string first "\{" $::libp::text [lindex $m 1]]
            lappend repl [list $lb $lb "\{\n  /* global variation corner $cname applied by apply_to_liberty.tcl : $npatch table(s) scaled */" ""]
        }
    }
    # apply replacements from the end
    set out $::libp::text
    foreach r [lsort -integer -decreasing -index 0 $repl] {
        lassign $r s e nt
        set out [string replace $out $s $e $nt]
    }
    set f [dict get $opt o]
    file mkdir [file dirname $f]
    set fh [open $f w]
    puts -nonewline $fh $out
    close $fh
    ::lvfgv::msg "wrote $f : $npatch table(s) scaled, $::libp::warn warning(s)"
}
main $argv
