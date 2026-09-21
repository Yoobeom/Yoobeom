#-----------------------------------------------------------------------
# File    : 07_common_cells.tcl
# Author  : youbumkim@gmail.com
# Purpose : Cells that appear in the most failing paths (fix these first)
# Tool    : PrimeTime (pt_shell)
# Usage   : source 07_common_cells.tcl ; common_cells_in_violators 30
#-----------------------------------------------------------------------

# Counts how many distinct failing paths pass through each leaf cell.
# A cell on 500 failing paths is a better ECO target than one on 2.
proc common_cells_in_violators {{top_n 30} {max_paths 2000} {delay_type max}} {
    set paths [get_timing_paths -delay_type $delay_type -nworst 1 \
                   -max_paths $max_paths -slack_lesser_than 0]
    array set n {}
    array set worst {}
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        array set seen {}
        foreach_in_collection pt [get_attribute $p points] {
            set obj [get_attribute $pt object]
            if {[get_attribute $obj object_class] ne "pin"} { continue }
            set cell [get_object_name [get_cells -of_objects $obj]]
            if {[info exists seen($cell)]} { continue }
            set seen($cell) 1
            if {[info exists n($cell)]} { incr n($cell) } else { set n($cell) 0; set worst($cell) 0 }
            if {$s < $worst($cell)} { set worst($cell) $s }
        }
        array unset seen
    }
    set rows {}
    foreach c [array names n] {
        lappend rows [list $c $n($c) $worst($c) [get_attribute [get_cells $c] ref_name]]
    }
    set rows [lsort -integer -decreasing -index 1 $rows]
    puts [format "%-55s %6s %9s  %s" CELL NPATH WORST REF]
    foreach r [lrange $rows 0 [expr {$top_n - 1}]] {
        lassign $r c cnt w ref
        puts [format "%-55s %6d %9.3f  %s" $c $cnt $w $ref]
    }
    return $rows
}
