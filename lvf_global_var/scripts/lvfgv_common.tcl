# ---------------------------------------------------------------------------
# File   : lvfgv_common.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Common procedures for the LVF-sensitivity based global variation
#          flow: configuration, CSV I/O, SPICE netlist parsing and
#          instrumentation, deck generation, simulator execution, measure
#          parsing, corner definition handling.
# Usage  : source [file join [file dirname [info script]] lvfgv_common.tcl]
# Tcl    : 8.5 or later (tclsh, or the Tcl shell of any EDA tool)
# ---------------------------------------------------------------------------
package require Tcl 8.5

namespace eval ::lvfgv {
    variable cfg
    array set cfg {}
    variable corner
    array set corner {}
    variable version 1.0
    variable jobstate
    array set jobstate {}
}

# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------
proc ::lvfgv::msg {args} {
    puts stderr "\[lvfgv\] [join $args]"
    flush stderr
}
proc ::lvfgv::die {args} {
    puts stderr "\[lvfgv\] ERROR: [join $args]"
    flush stderr
    exit 1
}

# ---------------------------------------------------------------------------
# Command line parsing: -key value pairs and -flag switches
#   parse_args $argv {cfg mode corner out} {gen_only skip_sim}
#   returns dict of options
# ---------------------------------------------------------------------------
proc ::lvfgv::parse_args {argv valued flags} {
    set opt [dict create]
    foreach f $flags { dict set opt $f 0 }
    set i 0
    set n [llength $argv]
    while {$i < $n} {
        set a [lindex $argv $i]
        if {![string match -* $a]} { die "unexpected argument: $a" }
        set key [string range $a 1 end]
        if {$key in $flags} {
            dict set opt $key 1
            incr i
        } elseif {$key in $valued} {
            incr i
            if {$i >= $n} { die "option -$key needs a value" }
            dict set opt $key [lindex $argv $i]
            incr i
        } else {
            die "unknown option: $a"
        }
    }
    return $opt
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
proc ::lvfgv::cfg_defaults {} {
    variable cfg
    array set cfg {
        sim_cmd         {ngspice -b -o %LOG% %DECK%}
        result_format   keyval
        result_file     %LOG%
        deck_ext        .sp
        model_include   {}
        netlist         {}
        out_dir         out
        vdd             1.0
        temp            25
        slews           {}
        loads           {}
        slew_lower      0.2
        slew_upper      0.8
        delay_thresh    0.5
        params          {vth u0}
        delta,vth       0.010
        delta,u0        0.02
        hook,vth        {delvto=%s}
        hook,u0         {mulu0=%s}
        hook_apply,vth  add
        hook_apply,u0   mul
        group_map       {{^nch} N {^pch} P}
        supply_map      {VDD vdd VSS 0}
        t_start         0.5e-9
        t_settle        3e-9
        tran_step       {}
        sim_options     {{.option reltol=1e-5 abstol=1e-14 vntol=1e-7 chgtol=1e-16}}
        group_sens      1
        jobs            1
        cells           {}
    }
}

proc ::lvfgv::load_cfg {file} {
    variable cfg
    array unset cfg
    cfg_defaults
    set f [file normalize $file]
    if {![file exists $f]} { die "config file not found: $file" }
    set cfg(cfg_dir)  [file dirname $f]
    set cfg(cfg_file) $f
    namespace eval ::lvfgv [list source $f]
    foreach k {netlist model_include cells slews loads} {
        if {![info exists cfg($k)] || $cfg($k) eq ""} { die "config: cfg($k) is required" }
    }
    set cfg(netlist)       [resolve_path $cfg(netlist)]
    set cfg(model_include) [resolve_path $cfg(model_include)]
    set cfg(out_dir)       [resolve_path $cfg(out_dir)]
    foreach p $cfg(params) {
        foreach k [list delta,$p hook,$p hook_apply,$p] {
            if {![info exists cfg($k)]} { die "config: cfg($k) is required for param $p" }
        }
        if {$cfg(hook_apply,$p) ni {add mul}} { die "config: cfg(hook_apply,$p) must be add or mul" }
    }
    foreach c $cfg(cells) {
        if {![info exists cfg(arcs,$c)]} { die "config: cfg(arcs,$c) is missing" }
        foreach arc $cfg(arcs,$c) {
            foreach k {name in in_dir out out_dir} {
                if {![dict exists $arc $k]} { die "config: arc of $c lacks key '$k': $arc" }
            }
        }
    }
    return
}

proc ::lvfgv::resolve_path {p} {
    variable cfg
    if {[file pathtype $p] eq "absolute"} { return $p }
    return [file normalize [file join $cfg(cfg_dir) $p]]
}

# Return the arc dict of a cell by arc name
proc ::lvfgv::get_arc {cell name} {
    variable cfg
    foreach arc $cfg(arcs,$cell) {
        if {[dict get $arc name] eq $name} { return $arc }
    }
    die "arc $name not defined for cell $cell"
}

# Default hook value (no perturbation) for a parameter
proc ::lvfgv::hook_default {param} {
    variable cfg
    if {$cfg(hook_apply,$param) eq "mul"} { return 1.0 }
    return 0.0
}
# Physical-to-hook sign of a group/param (cfg(shift_sign,<group>,<param>),
# default +1).  Example: BSIM4 delvto adds to the signed vth0, so for PMOS a
# +|Vth| (slower) shift needs delvto < 0  ->  set cfg(shift_sign,P,vth) -1
proc ::lvfgv::shift_sign {group param} {
    variable cfg
    if {[info exists cfg(shift_sign,$group,$param)]} { return $cfg(shift_sign,$group,$param) }
    return 1
}
# Hook value for a physical shift of one device (add: s*shift, mul: 1+s*shift)
proc ::lvfgv::hook_value {param shift {group ""}} {
    variable cfg
    set s 1
    if {$group ne ""} { set s [shift_sign $group $param] }
    if {$cfg(hook_apply,$param) eq "mul"} { return [expr {1.0 + $s * $shift}] }
    return [expr {double($s * $shift)}]
}
# Deck parameter name carrying the perturbation of one instance
proc ::lvfgv::pname {param inst} {
    return "lv_${param}_${inst}"
}

# ---------------------------------------------------------------------------
# Numbers
# ---------------------------------------------------------------------------
proc ::lvfgv::si2num {s} {
    set s [string trim $s " '\"{}"]
    if {[string is double -strict $s]} { return [expr {double($s)}] }
    if {![regexp -nocase {^([-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:e[-+]?[0-9]+)?)([a-z]+)$} $s -> num suf]} {
        return -code error "cannot parse number: $s"
    }
    set suf [string tolower $suf]
    if {[string match meg* $suf]} {
        set scale 1e6
    } elseif {[string match mil* $suf]} {
        set scale 25.4e-6
    } else {
        switch -- [string index $suf 0] {
            t { set scale 1e12 }
            g { set scale 1e9 }
            x { set scale 1e6 }
            k { set scale 1e3 }
            m { set scale 1e-3 }
            u { set scale 1e-6 }
            n { set scale 1e-9 }
            p { set scale 1e-12 }
            f { set scale 1e-15 }
            a { set scale 1e-18 }
            default { return -code error "unknown unit suffix in: $s" }
        }
    }
    return [expr {double($num) * $scale}]
}

proc ::lvfgv::fnum {v {fmt %.6e}} {
    return [format $fmt $v]
}

proc ::lvfgv::is_num {v} {
    return [string is double -strict $v]
}

# ---------------------------------------------------------------------------
# CSV I/O (simple quoting: fields with , or " are double quoted)
# ---------------------------------------------------------------------------
proc ::lvfgv::csv_quote {f} {
    if {[string first , $f] >= 0 || [string first \" $f] >= 0 || [string first \n $f] >= 0} {
        return "\"[string map {\" \"\"} $f]\""
    }
    return $f
}
proc ::lvfgv::csv_split {line} {
    set out {}
    set cur ""
    set inq 0
    set n [string length $line]
    for {set i 0} {$i < $n} {incr i} {
        set c [string index $line $i]
        if {$inq} {
            if {$c eq "\""} {
                if {[string index $line [expr {$i+1}]] eq "\""} {
                    append cur "\""
                    incr i
                } else {
                    set inq 0
                }
            } else {
                append cur $c
            }
        } else {
            if {$c eq "\""} {
                set inq 1
            } elseif {$c eq ","} {
                lappend out $cur
                set cur ""
            } else {
                append cur $c
            }
        }
    }
    lappend out $cur
    return $out
}
proc ::lvfgv::csv_write {file header rows} {
    file mkdir [file dirname $file]
    set fh [open $file w]
    puts $fh [join [lmap f $header {csv_quote $f}] ,]
    foreach r $rows {
        puts $fh [join [lmap f $r {csv_quote $f}] ,]
    }
    close $fh
}
# returns list: header, list-of-dicts (keyed by header)
proc ::lvfgv::csv_read {file} {
    if {![file exists $file]} { die "file not found: $file" }
    set fh [open $file r]
    set header {}
    set rows {}
    while {[gets $fh line] >= 0} {
        if {[string trim $line] eq ""} { continue }
        if {[string index $line 0] eq "#"} { continue }
        set f [csv_split $line]
        if {[llength $header] == 0} {
            set header $f
            continue
        }
        set d [dict create]
        for {set i 0} {$i < [llength $header]} {incr i} {
            dict set d [lindex $header $i] [lindex $f $i]
        }
        lappend rows $d
    }
    close $fh
    return [list $header $rows]
}

# ---------------------------------------------------------------------------
# Netlist parsing
#   read_netlist file -> list {order subdict}
#   subdict: name -> {ports {..} header {..} lines {..}}
# ---------------------------------------------------------------------------
proc ::lvfgv::read_netlist {file} {
    if {![file exists $file]} { die "netlist not found: $file" }
    set fh [open $file r]
    set raw [read $fh]
    close $fh
    set lines {}
    foreach l [split $raw \n] {
        set l [string trimright $l]
        if {[regexp {^\s*\+(.*)$} $l -> rest]} {
            if {[llength $lines] == 0} { continue }
            lset lines end "[lindex $lines end] $rest"
        } else {
            lappend lines $l
        }
    }
    set sub [dict create]
    set order {}
    set cur ""
    foreach l $lines {
        set t [string trim $l]
        if {$t eq "" || [string index $t 0] eq "*"} { continue }
        regsub {\s+\$.*$} $t {} t
        if {[regexp -nocase {^\.subckt\s+(\S+)\s*(.*)$} $t -> name rest]} {
            set cur $name
            set ports {}
            foreach tok $rest {
                if {[string first = $tok] >= 0} { break }
                lappend ports $tok
            }
            dict set sub $cur ports $ports
            dict set sub $cur header $t
            dict set sub $cur lines {}
            lappend order $cur
        } elseif {[regexp -nocase {^\.ends} $t]} {
            set cur ""
        } elseif {$cur ne ""} {
            set cl [dict get $sub $cur lines]
            lappend cl $t
            dict set sub $cur lines $cl
        }
    }
    return [list $order $sub]
}

proc ::lvfgv::find_subckt {sub cell} {
    dict for {name d} $sub {
        if {[string equal -nocase $name $cell]} { return $name }
    }
    die "subckt $cell not found in netlist"
}

proc ::lvfgv::model_group {model} {
    variable cfg
    foreach {re grp} $cfg(group_map) {
        if {[regexp -nocase -- $re $model]} { return $grp }
    }
    return ""
}

# Devices of a cell that belong to a variation group.
# Returns list of dicts {inst model group w l nf m line}
proc ::lvfgv::cell_devices {sub cell} {
    set devs {}
    set idx 0
    foreach l [dict get $sub $cell lines] {
        regsub -all {\s*=\s*} $l = l2
        set toks [regexp -all -inline {\S+} $l2]
        set name [lindex $toks 0]
        set c [string toupper [string index $name 0]]
        if {$c ni {M X}} { incr idx; continue }
        set model ""
        set kv [dict create]
        foreach tok [lrange $toks 1 end] {
            set eq [string first = $tok]
            if {$eq >= 0} {
                dict set kv [string tolower [string range $tok 0 [expr {$eq-1}]]] [string range $tok [expr {$eq+1}] end]
            } else {
                set model $tok
            }
        }
        set grp [model_group $model]
        if {$grp ne ""} {
            set w 0.0; set len 0.0; set nf 1.0; set m 1.0
            if {[dict exists $kv w]}    { catch {set w   [si2num [dict get $kv w]]} }
            if {[dict exists $kv l]}    { catch {set len [si2num [dict get $kv l]]} }
            if {[dict exists $kv nf]}   { catch {set nf  [si2num [dict get $kv nf]]} }
            if {[dict exists $kv nfin]} { catch {set nf  [si2num [dict get $kv nfin]]} }
            if {[dict exists $kv m]}    { catch {set m   [si2num [dict get $kv m]]} }
            lappend devs [dict create inst $name model $model group $grp \
                              w $w l $len nf $nf m $m line $idx]
        }
        incr idx
    }
    return $devs
}

# Instrumented subckt text of the whole netlist: every device of the target
# cell carries the perturbation hooks referencing deck parameters lv_<p>_<inst>.
# Returns list {text params} where params is list of {pname default}.
proc ::lvfgv::instrument_netlist {order sub cell devs} {
    variable cfg
    set params {}
    set hookkeys {}
    foreach p $cfg(params) {
        set h [format $cfg(hook,$p) X]
        set eq [string first = $h]
        lappend hookkeys [string tolower [string range $h 0 [expr {$eq-1}]]]
    }
    set out {}
    foreach name $order {
        lappend out [dict get $sub $name header]
        set lines [dict get $sub $name lines]
        if {$name eq $cell} {
            foreach dev $devs {
                set idx [dict get $dev line]
                set inst [dict get $dev inst]
                set l [lindex $lines $idx]
                regsub -all {\s*=\s*} $l = l
                set toks {}
                foreach tok [regexp -all -inline {\S+} $l] {
                    set eq [string first = $tok]
                    if {$eq >= 0 && [string tolower [string range $tok 0 [expr {$eq-1}]]] in $hookkeys} { continue }
                    lappend toks $tok
                }
                foreach p $cfg(params) {
                    set pn [pname $p $inst]
                    lappend toks [format $cfg(hook,$p) $pn]
                    lappend params [list $pn [hook_default $p]]
                }
                lset lines $idx [join $toks " "]
            }
        }
        foreach l $lines { lappend out $l }
        lappend out ".ends $name"
        lappend out ""
    }
    return [list [join $out \n] $params]
}

# ---------------------------------------------------------------------------
# Deck generation
#   pstate : dict pname -> value (overrides of the hook parameters)
#   Every (slew,load) point of the table is a separate copy of the cell in the
#   same deck, so one simulation covers the complete table for one state.
# ---------------------------------------------------------------------------
proc ::lvfgv::port_node {port arc j k} {
    variable cfg
    set in  [dict get $arc in]
    set out [dict get $arc out]
    if {[string equal -nocase $port $in]}  { return "in_${j}_${k}" }
    if {[string equal -nocase $port $out]} { return "out_${j}_${k}" }
    if {[dict exists $arc side]} {
        foreach {pin val} [dict get $arc side] {
            if {[string equal -nocase $port $pin]} {
                if {$val} { return vdd } else { return 0 }
            }
        }
    }
    foreach {sp node} $cfg(supply_map) {
        if {[string equal -nocase $port $sp]} { return $node }
    }
    die "port $port of arc [dict get $arc name] has no connection (add to arc side {} or cfg(supply_map))"
}

proc ::lvfgv::tran_step {} {
    variable cfg
    if {$cfg(tran_step) ne ""} { return $cfg(tran_step) }
    set smin [lindex [lsort -real $cfg(slews)] 0]
    set step [expr {$smin / ($cfg(slew_upper) - $cfg(slew_lower)) / 100.0}]
    if {$step > 1e-12} { set step 1e-12 }
    if {$step < 5e-14} { set step 5e-14 }
    return $step
}

proc ::lvfgv::gen_deck {file cell arc state pstate subtext params ports} {
    variable cfg
    set vdd   [expr {double($cfg(vdd))}]
    set lo    $cfg(slew_lower)
    set hi    $cfg(slew_upper)
    set th    $cfg(delay_thresh)
    set t0    [expr {double($cfg(t_start))}]
    set smax  [lindex [lsort -real -decreasing $cfg(slews)] 0]
    set trmax [expr {$smax / ($hi - $lo)}]
    set tstop [expr {$t0 + $trmax + $cfg(t_settle)}]
    set step  [tran_step]
    set indir  [dict get $arc in_dir]
    set outdir [dict get $arc out_dir]
    set arcname [dict get $arc name]

    file mkdir [file dirname $file]
    set fh [open $file w]
    puts $fh "* LVF global variation flow  cell=$cell arc=$arcname state=$state"
    puts $fh "* generated by tr_sens_char.tcl"
    puts $fh ".temp $cfg(temp)"
    foreach o $cfg(sim_options) { puts $fh $o }
    puts $fh ".param vdd=[fnum $vdd %.6g]"
    puts $fh "* perturbation parameters (state $state; unperturbed devices at default)"
    foreach pd $params {
        lassign $pd pn def
        if {[dict exists $pstate $pn]} {
            puts $fh ".param $pn=[fnum [dict get $pstate $pn] %.8g]"
        } else {
            puts $fh ".param $pn=[fnum $def %.8g]"
        }
    }
    puts $fh ".include $cfg(model_include)"
    puts $fh ""
    puts $fh $subtext
    puts $fh "vdd vdd 0 [fnum $vdd %.6g]"
    if {$indir eq "rise"} {
        set v_a 0.0; set v_b $vdd
        set in_edge rise
    } else {
        set v_a $vdd; set v_b 0.0
        set in_edge fall
    }
    if {$outdir eq "rise"} {
        set out_edge rise
        set s_v1 [expr {$lo * $vdd}]; set s_v2 [expr {$hi * $vdd}]
    } else {
        set out_edge fall
        set s_v1 [expr {$hi * $vdd}]; set s_v2 [expr {$lo * $vdd}]
    }
    set vth [expr {$th * $vdd}]
    set j 0
    foreach slew $cfg(slews) {
        set tr [expr {$slew / ($hi - $lo)}]
        set k 0
        foreach load $cfg(loads) {
            set nin  "in_${j}_${k}"
            set nout "out_${j}_${k}"
            puts $fh "* ---- point slew_idx=$j load_idx=$k slew=[fnum $slew] load=[fnum $load]"
            puts $fh "v_${j}_${k} $nin 0 pwl(0 [fnum $v_a %.6g] [fnum $t0] [fnum $v_a %.6g] [fnum [expr {$t0+$tr}]] [fnum $v_b %.6g])"
            set nodes {}
            foreach port $ports { lappend nodes [port_node $port $arc $j $k] }
            puts $fh "x_${j}_${k} [join $nodes " "] $cell"
            puts $fh "c_${j}_${k} $nout 0 [fnum $load]"
            puts $fh ".measure tran d_${j}_${k} trig v($nin) val=[fnum $vth %.6g] ${in_edge}=1 targ v($nout) val=[fnum $vth %.6g] ${out_edge}=1"
            puts $fh ".measure tran s_${j}_${k} trig v($nout) val=[fnum $s_v1 %.6g] ${out_edge}=1 targ v($nout) val=[fnum $s_v2 %.6g] ${out_edge}=1"
            incr k
        }
        incr j
    }
    puts $fh ""
    puts $fh ".tran [fnum $step] [fnum $tstop]"
    puts $fh ".end"
    close $fh
}

# ---------------------------------------------------------------------------
# Simulator command / result file for a deck
# ---------------------------------------------------------------------------
proc ::lvfgv::sim_paths {deck} {
    variable cfg
    set base [file rootname $deck]
    set log  "$base.log"
    set map [list %DECK% $deck %LOG% $log %BASE% $base %DIR% [file dirname $deck]]
    set cmd [string map $map $cfg(sim_cmd)]
    set res [string map $map $cfg(result_file)]
    return [list $cmd $res $log]
}

# ---------------------------------------------------------------------------
# Parallel job runner (shell commands), njobs concurrent
# ---------------------------------------------------------------------------
proc ::lvfgv::run_jobs {cmds njobs} {
    variable jobstate
    array unset jobstate
    set jobstate(pending)  $cmds
    set jobstate(running)  0
    set jobstate(done)     0
    set jobstate(total)    [llength $cmds]
    set jobstate(failed)   {}
    set jobstate(njobs)    [expr {$njobs < 1 ? 1 : $njobs}]
    set jobstate(finished) 0
    if {$jobstate(total) == 0} { return {} }
    msg "running $jobstate(total) simulations ($jobstate(njobs) parallel)"
    job_fill
    vwait ::lvfgv::jobstate(finished)
    return $jobstate(failed)
}
proc ::lvfgv::job_fill {} {
    variable jobstate
    while {$jobstate(running) < $jobstate(njobs) && [llength $jobstate(pending)] > 0} {
        set cmd [lindex $jobstate(pending) 0]
        set jobstate(pending) [lrange $jobstate(pending) 1 end]
        if {[catch {open [list | /bin/sh -c $cmd 2>@1] r} ch]} {
            lappend jobstate(failed) [list $cmd $ch]
            incr jobstate(done)
            continue
        }
        fconfigure $ch -blocking 0
        fileevent $ch readable [list ::lvfgv::job_read $ch $cmd]
        incr jobstate(running)
    }
    if {$jobstate(running) == 0 && [llength $jobstate(pending)] == 0} {
        set jobstate(finished) 1
    }
}
proc ::lvfgv::job_read {ch cmd} {
    variable jobstate
    read $ch
    if {[eof $ch]} {
        fconfigure $ch -blocking 1
        if {[catch {close $ch} err]} {
            lappend jobstate(failed) [list $cmd $err]
        }
        incr jobstate(running) -1
        incr jobstate(done)
        if {$jobstate(done) % 20 == 0 || $jobstate(done) == $jobstate(total)} {
            msg "  $jobstate(done)/$jobstate(total) done"
        }
        job_fill
    }
}

# ---------------------------------------------------------------------------
# Measure result parsing -> dict name(lowercase) -> value
#   keyval : lines "name = value ..."  (ngspice log, spectre .measure)
#   mt0    : HSPICE measure table (.mt0)
# ---------------------------------------------------------------------------
proc ::lvfgv::parse_measures {file} {
    variable cfg
    set res [dict create]
    if {![file exists $file]} { return $res }
    set fh [open $file r]
    set txt [read $fh]
    close $fh
    if {$cfg(result_format) eq "mt0"} {
        set toks {}
        foreach l [split $txt \n] {
            set t [string trim $l]
            if {$t eq "" || [string index $t 0] eq "\$" || [string match -nocase ".title*" $t]} { continue }
            foreach tok $t { lappend toks $tok }
        }
        set names {}
        set i 0
        foreach tok $toks {
            if {[is_num $tok]} { break }
            lappend names [string tolower $tok]
            incr i
        }
        set vals [lrange $toks $i end]
        for {set n 0} {$n < [llength $names]} {incr n} {
            set v [lindex $vals $n]
            if {[is_num $v]} { dict set res [lindex $names $n] $v }
        }
    } else {
        foreach l [split $txt \n] {
            if {[regexp {^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][-+]?[0-9]+)?)(?:\s|$)} $l -> n v]} {
                dict set res [string tolower $n] $v
            }
        }
    }
    return $res
}

# ---------------------------------------------------------------------------
# Corner definitions
#   set corner(NAME) {{group param unit value} ...}   unit: abs | sigma
#   corner_shifts NAME -> dict "group,param" -> absolute shift
# ---------------------------------------------------------------------------
proc ::lvfgv::load_corners {file} {
    variable corner
    array unset corner
    set f [file normalize $file]
    if {![file exists $f]} { die "corner file not found: $file" }
    namespace eval ::lvfgv [list source $f]
    return [lsort [array names corner]]
}
proc ::lvfgv::corner_names {} {
    variable corner
    set names {}
    foreach n [lsort [array names corner]] {
        if {[string first , $n] < 0} { lappend names $n }
    }
    return $names
}
proc ::lvfgv::corner_shifts {name} {
    variable corner
    variable cfg
    if {![info exists corner($name)]} { die "corner $name not defined" }
    set d [dict create]
    foreach e $corner($name) {
        if {[llength $e] != 4} { die "corner $name: entry must be {group param unit value}: $e" }
        lassign $e grp p unit val
        if {$p ni $cfg(params)} { die "corner $name: param $p not in cfg(params)" }
        switch -- $unit {
            abs   { set shift [expr {double($val)}] }
            sigma {
                if {![info exists cfg(sigma_g,$grp,$p)]} { die "corner $name: cfg(sigma_g,$grp,$p) needed for sigma unit" }
                set shift [expr {double($val) * $cfg(sigma_g,$grp,$p)}]
            }
            default { die "corner $name: unit must be abs or sigma: $e" }
        }
        dict set d "$grp,$p" $shift
    }
    return $d
}

# ---------------------------------------------------------------------------
# Mismatch sigma of one device for a parameter (used for LVF local sigma and
# contribution reporting).  cfg(sigma_mm,<group>,<param>):
#   {pelgrom A}  sigma = A / sqrt(W_um * L_um * NF * M)
#   {const  s}   sigma = s
# ---------------------------------------------------------------------------
proc ::lvfgv::mismatch_sigma {dev param} {
    variable cfg
    set grp [dict get $dev group]
    if {![info exists cfg(sigma_mm,$grp,$param)]} { return "" }
    lassign $cfg(sigma_mm,$grp,$param) kind a
    switch -- $kind {
        pelgrom {
            set w  [expr {[dict get $dev w] * 1e6}]
            set l  [expr {[dict get $dev l] * 1e6}]
            set nf [dict get $dev nf]
            set m  [dict get $dev m]
            set area [expr {$w * $l * $nf * $m}]
            if {$area <= 0} { return "" }
            return [expr {$a / sqrt($area)}]
        }
        const { return [expr {double($a)}] }
        default { die "cfg(sigma_mm,$grp,$param): kind must be pelgrom or const" }
    }
}

# ---------------------------------------------------------------------------
# Small statistics helpers
# ---------------------------------------------------------------------------
proc ::lvfgv::lmax {l} { return [lindex [lsort -real -decreasing $l] 0] }
proc ::lvfgv::lmin {l} { return [lindex [lsort -real $l] 0] }
proc ::lvfgv::lmean {l} {
    if {[llength $l] == 0} { return 0.0 }
    set s 0.0
    foreach v $l { set s [expr {$s + $v}] }
    return [expr {$s / [llength $l]}]
}
proc ::lvfgv::lrms {l} {
    if {[llength $l] == 0} { return 0.0 }
    set s 0.0
    foreach v $l { set s [expr {$s + $v*$v}] }
    return [expr {sqrt($s / [llength $l])}]
}
