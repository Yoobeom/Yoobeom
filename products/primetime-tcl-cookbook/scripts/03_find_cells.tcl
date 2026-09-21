#-----------------------------------------------------------------------
# File    : 03_find_cells.tcl
# Author  : youbumkim@gmail.com
# Purpose : Design query recipes: cells, pins, nets by type and name
# Tool    : PrimeTime (pt_shell)
# Usage   : source 03_find_cells.tcl
#-----------------------------------------------------------------------

# All leaf flops in the design (excludes hierarchy cells, ICGs, latches).
proc all_flops {} {
    return [get_cells -hierarchical -filter \
        "is_sequential == true && is_hierarchical == false && \
         is_integrated_clock_gating_cell == false"]
}

# Cells under a hierarchy, matching a ref_name glob.
# find_cells_under u_core/u_alu DFF*
proc find_cells_under {hier ref_glob} {
    return [get_cells -hierarchical -filter \
        "full_name =~ ${hier}/* && ref_name =~ ${ref_glob}"]
}

# Count cells per lib cell name (ref_name) under a hierarchy.
proc cell_histogram {{hier ""} {top_n 20}} {
    if {$hier eq ""} {
        set cells [get_cells -hierarchical -filter "is_hierarchical == false"]
    } else {
        set cells [get_cells -hierarchical -filter \
            "full_name =~ ${hier}/* && is_hierarchical == false"]
    }
    array set h {}
    foreach_in_collection c $cells {
        set r [get_attribute $c ref_name]
        if {[info exists h($r)]} { incr h($r) } else { set h($r) 1 }
    }
    set rows {}
    foreach r [array names h] { lappend rows [list $r $h($r)] }
    set rows [lsort -integer -decreasing -index 1 $rows]
    puts [format "%-40s %8s" REF_NAME COUNT]
    foreach row [lrange $rows 0 [expr {$top_n - 1}]] {
        puts [format "%-40s %8d" [lindex $row 0] [lindex $row 1]]
    }
    return $rows
}

# Total std-cell area under a hierarchy.
proc area_under {hier} {
    set total 0.0
    foreach_in_collection c [get_cells -hierarchical -filter \
            "full_name =~ ${hier}/* && is_hierarchical == false"] {
        set a [get_attribute -quiet $c area]
        if {[string is double -strict $a]} { set total [expr {$total + $a}] }
    }
    return $total
}

# Hierarchy cells directly under the top (first level only).
proc top_level_blocks {} {
    return [get_cells -filter "is_hierarchical == true"]
}

# All pins driven by a given lib cell type, e.g. output pins of all ICGs.
proc pins_of_ref {ref_glob {dir out}} {
    set cells [get_cells -hierarchical -filter "ref_name =~ $ref_glob"]
    if {$cells eq ""} { return "" }
    return [get_pins -of_objects $cells -filter "direction == $dir"]
}
