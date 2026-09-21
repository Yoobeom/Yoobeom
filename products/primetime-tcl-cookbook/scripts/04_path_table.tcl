#-----------------------------------------------------------------------
# File    : 04_path_table.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : One-line-per-path table from get_timing_paths attributes
# Tool    : PrimeTime (pt_shell)
# Usage   : source 04_path_table.tcl ; path_table -group CLK -max_paths 200
#-----------------------------------------------------------------------

# Prints and returns rows of:
#   slack startpoint endpoint launch_clk capture_clk group arrival required
# Options: -group -max_paths -nworst -delay_type -slack_lesser_than -out
proc path_table {args} {
    array set opt {-group {} -max_paths 100 -nworst 1 -delay_type max
                   -slack_lesser_than 0 -out ""}
    array set opt $args

    set cmd [list get_timing_paths -delay_type $opt(-delay_type) \
                 -max_paths $opt(-max_paths) -nworst $opt(-nworst) \
                 -slack_lesser_than $opt(-slack_lesser_than)]
    if {$opt(-group) ne ""} { lappend cmd -group $opt(-group) }
    set paths [eval $cmd]

    set rows {}
    foreach_in_collection p $paths {
        set slack  [get_attribute $p slack]
        set sp     [get_object_name [get_attribute $p startpoint]]
        set ep     [get_object_name [get_attribute $p endpoint]]
        set lclk   [get_object_name [get_attribute -quiet $p startpoint_clock]]
        set cclk   [get_object_name [get_attribute -quiet $p endpoint_clock]]
        set grp    [get_object_name [get_attribute $p path_group]]
        set arr    [get_attribute -quiet $p arrival]
        set req    [get_attribute -quiet $p required]
        lappend rows [list $slack $sp $ep $lclk $cclk $grp $arr $req]
    }

    set fmt "%9s  %-45s %-45s %-12s %-12s %-10s %9s %9s"
    set hdr [format $fmt SLACK STARTPOINT ENDPOINT LAUNCH CAPTURE GROUP ARRIVAL REQUIRED]
    if {$opt(-out) ne ""} {
        set fh [open $opt(-out) w]
        puts $fh $hdr
        foreach r $rows { puts $fh [eval format [list $fmt] $r] }
        close $fh
        puts "wrote [llength $rows] paths to $opt(-out)"
    } else {
        puts $hdr
        foreach r $rows { puts [eval format [list $fmt] $r] }
    }
    return $rows
}
