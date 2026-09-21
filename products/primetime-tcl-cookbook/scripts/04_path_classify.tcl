#-----------------------------------------------------------------------
# File    : 04_path_classify.tcl
# Author  : youbumkim@gmail.com
# Purpose : Classify failing paths as reg2reg / in2reg / reg2out / in2out
# Tool    : PrimeTime (pt_shell)
# Usage   : source 04_path_classify.tcl ; classify_violators
#-----------------------------------------------------------------------

proc path_class {path} {
    set sp [get_attribute $path startpoint]
    set ep [get_attribute $path endpoint]
    set sc [get_attribute $sp object_class]
    set ec [get_attribute $ep object_class]
    set s [expr {$sc eq "port" ? "in"  : "reg"}]
    set e [expr {$ec eq "port" ? "out" : "reg"}]
    # macro pins are still "reg" class here; refine with is_hierarchical
    # on the parent cell when memories need their own bucket
    if {$sc eq "pin"} {
        set cell [get_cells -of_objects $sp]
        if {[get_attribute -quiet $cell is_black_box] eq "true"} { set s "macro" }
    }
    if {$ec eq "pin"} {
        set cell [get_cells -of_objects $ep]
        if {[get_attribute -quiet $cell is_black_box] eq "true"} { set e "macro" }
    }
    return "${s}2${e}"
}

proc classify_violators {{delay_type max} {max_paths 20000}} {
    set paths [get_timing_paths -delay_type $delay_type -nworst 1 \
                   -max_paths $max_paths -slack_lesser_than 0]
    array set n {}
    array set w {}
    array set tns {}
    foreach_in_collection p $paths {
        set cls [path_class $p]
        set s [get_attribute $p slack]
        if {![info exists n($cls)]} { set n($cls) 0; set w($cls) 0; set tns($cls) 0.0 }
        incr n($cls)
        set tns($cls) [expr {$tns($cls) + $s}]
        if {$s < $w($cls)} { set w($cls) $s }
    }
    puts [format "%-12s %8s %10s %12s" CLASS COUNT WNS TNS]
    foreach cls [lsort [array names n]] {
        puts [format "%-12s %8d %10.3f %12.3f" $cls $n($cls) $w($cls) $tns($cls)]
    }
}
