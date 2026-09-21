#-----------------------------------------------------------------------
# File    : 08_eco_upsize.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Try-and-keep upsizing loop with incremental timing checks
# Tool    : PrimeTime (pt_shell), requires ECO (size_cell) capability
# Usage   : source 08_eco_upsize.tcl ; eco_upsize_loop cand.csv -limit 200
#-----------------------------------------------------------------------

# Reads candidate cells (first CSV column), tries the next drive strength
# from get_alternative_lib_cells, keeps the change only if the worst
# slack of the paths through the cell improves and no new DRV appears.
#
# Drive strength is inferred from a trailing X<n> or D<n> in the lib cell
# name. Adjust the regexp for your library naming.
proc drive_of {libcell_name} {
    if {[regexp {[XD](\d+)[A-Z]*$} $libcell_name -> d]} { return $d }
    return 0
}

proc next_bigger_libcell {cell} {
    set cur [get_attribute $cell ref_name]
    set cur_d [drive_of $cur]
    set best ""
    set best_d 1e9
    foreach_in_collection alt [get_alternative_lib_cells -quiet $cell] {
        set n [get_attribute $alt base_name]
        set d [drive_of $n]
        if {$d > $cur_d && $d < $best_d} { set best_d $d; set best $alt }
    }
    return $best
}

proc worst_slack_through {cell} {
    set pins [get_pins -of_objects $cell -filter "direction == out"]
    set p [get_timing_paths -through $pins -nworst 1 -max_paths 1]
    if {$p eq ""} { return 1e9 }
    return [get_attribute $p slack]
}

proc eco_upsize_loop {csv args} {
    array set opt {-limit 100 -log eco_upsize.log}
    array set opt $args
    set fh [open $csv r]
    gets $fh ;# header
    set cells {}
    while {[gets $fh line] >= 0} {
        set c [lindex [split $line ","] 0]
        if {$c ne ""} { lappend cells $c }
    }
    close $fh
    set log [open $opt(-log) w]
    set n_try 0
    set n_keep 0
    foreach cname [lrange $cells 0 [expr {$opt(-limit) - 1}]] {
        set cell [get_cells -quiet $cname]
        if {$cell eq ""} { continue }
        set alt [next_bigger_libcell $cell]
        if {$alt eq ""} { puts $log "$cname : no larger alternative"; continue }
        set before [worst_slack_through $cell]
        set old_ref [get_attribute $cell ref_name]
        incr n_try
        size_cell $cell $alt
        update_timing
        set after [worst_slack_through $cell]
        if {$after > $before + 0.001} {
            incr n_keep
            puts $log [format "%s : %s -> %s  slack %.3f -> %.3f  KEEP" \
                $cname $old_ref [get_attribute $alt base_name] $before $after]
        } else {
            # revert: size back to the original lib cell
            set orig [get_lib_cells -quiet */$old_ref]
            size_cell $cell [index_collection $orig 0]
            update_timing
            puts $log [format "%s : %s -> %s  slack %.3f -> %.3f  REVERT" \
                $cname $old_ref [get_attribute $alt base_name] $before $after]
        }
    }
    close $log
    puts "tried $n_try, kept $n_keep (log: $opt(-log))"
    return $n_keep
}
