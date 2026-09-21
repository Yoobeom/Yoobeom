#-----------------------------------------------------------------------
# File    : 04_path_points.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Walk the points of a path to find the largest stage delays
# Tool    : PrimeTime (pt_shell)
# Usage   : source 04_path_points.tcl ; biggest_stages [get_timing_paths] 5
#-----------------------------------------------------------------------

# Prints the N stages (point-to-point increments) with the largest delay
# in a path, with the cell ref_name and transition at that point.
proc biggest_stages {path {top_n 5}} {
    set prev_arr ""
    set rows {}
    foreach_in_collection pt [get_attribute $path points] {
        set obj  [get_attribute $pt object]
        set arr  [get_attribute $pt arrival]
        set tran [get_attribute -quiet $pt transition]
        set name [get_object_name $obj]
        set ref  ""
        if {[get_attribute $obj object_class] eq "pin"} {
            set ref [get_attribute -quiet [get_cells -of_objects $obj] ref_name]
        }
        if {$prev_arr ne "" && [string is double -strict $arr]} {
            lappend rows [list [expr {$arr - $prev_arr}] $name $ref $tran]
        }
        set prev_arr $arr
    }
    set rows [lsort -real -decreasing -index 0 $rows]
    puts [format "%8s  %-50s %-20s %8s" INCR POINT REF TRAN]
    foreach r [lrange $rows 0 [expr {$top_n - 1}]] {
        lassign $r d n ref t
        puts [format "%8.3f  %-50s %-20s %8s" $d $n $ref $t]
    }
    return $rows
}

# Sum of cell delay vs net delay along a path, approximated as:
#  cell stage = increment where point is an output pin
#  net  stage = increment where point is an input pin
proc cell_net_split {path} {
    set prev_arr ""
    set cell 0.0
    set net  0.0
    foreach_in_collection pt [get_attribute $path points] {
        set obj [get_attribute $pt object]
        set arr [get_attribute $pt arrival]
        if {$prev_arr ne "" && [string is double -strict $arr]} {
            set d [expr {$arr - $prev_arr}]
            set dir [get_attribute -quiet $obj direction]
            if {$dir eq "in"} { set net [expr {$net + $d}] } else { set cell [expr {$cell + $d}] }
        }
        set prev_arr $arr
    }
    return [list $cell $net]
}
