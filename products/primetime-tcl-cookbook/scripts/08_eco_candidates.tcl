#-----------------------------------------------------------------------
# File    : 08_eco_candidates.tcl
# Author  : youbumkim@gmail.com
# Purpose : Pick upsizing candidates on failing paths and rank them
# Tool    : PrimeTime (pt_shell)
# Usage   : source 08_eco_candidates.tcl ; eco_size_candidates -out cand.csv
#-----------------------------------------------------------------------

# Candidate = leaf cell on a failing path whose output transition is the
# slowest on the path, that is not dont_touch, and that has a larger
# alternative lib cell available (same footprint check is left to the
# implementation tool).
proc eco_size_candidates {args} {
    array set opt {-max_paths 1000 -out "" -min_slack -1.0 -skip_ref {DLY* *CKBUF* *ICG*}}
    array set opt $args
    set paths [get_timing_paths -delay_type max -nworst 1 -max_paths $opt(-max_paths) \
                   -slack_lesser_than 0 -slack_greater_than $opt(-min_slack)]
    array set score {}
    array set worst {}
    array set ref {}
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        set best_tran 0
        set best_cell ""
        foreach_in_collection pt [get_attribute $p points] {
            set obj [get_attribute $pt object]
            if {[get_attribute $obj object_class] ne "pin"} { continue }
            if {[get_attribute -quiet $obj direction] ne "out"} { continue }
            set tr [get_attribute -quiet $pt transition]
            if {![string is double -strict $tr]} { continue }
            set cell [get_cells -of_objects $obj]
            if {[get_attribute -quiet $cell dont_touch] eq "true"} { continue }
            if {[get_attribute -quiet $cell is_sequential] eq "true"} { continue }
            set r [get_attribute $cell ref_name]
            set skip 0
            foreach g $opt(-skip_ref) { if {[string match $g $r]} { set skip 1 } }
            if {$skip} { continue }
            if {$tr > $best_tran} {
                set best_tran $tr
                set best_cell [get_object_name $cell]
                set best_ref $r
            }
        }
        if {$best_cell eq ""} { continue }
        if {![info exists score($best_cell)]} {
            set score($best_cell) 0; set worst($best_cell) 0; set ref($best_cell) $best_ref
        }
        incr score($best_cell)
        if {$s < $worst($best_cell)} { set worst($best_cell) $s }
    }
    set rows {}
    foreach c [array names score] {
        set alts [get_alternative_lib_cells -quiet [get_cells $c]]
        set nalt 0
        if {$alts ne ""} { set nalt [sizeof_collection $alts] }
        lappend rows [list $c $ref($c) $score($c) $worst($c) $nalt]
    }
    set rows [lsort -integer -decreasing -index 2 $rows]
    puts [format "%-55s %-18s %6s %9s %5s" CELL REF NPATH WORST NALT]
    foreach r $rows {
        lassign $r c ref n w nalt
        puts [format "%-55s %-18s %6d %9.3f %5d" $c $ref $n $w $nalt]
    }
    if {$opt(-out) ne ""} {
        set fh [open $opt(-out) w]
        puts $fh "cell,ref_name,npath,worst_slack,n_alternatives"
        foreach r $rows { puts $fh [join $r ","] }
        close $fh
    }
    return $rows
}
