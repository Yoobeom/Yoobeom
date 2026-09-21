#-----------------------------------------------------------------------
# File    : 08_write_eco.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Export ECO changes for the implementation tool and verify
# Tool    : PrimeTime (pt_shell)
# Usage   : source 08_write_eco.tcl ; export_eco eco_out
#-----------------------------------------------------------------------

proc export_eco {dir} {
    file mkdir $dir
    # Native formats. Pick the one the P&R tool consumes.
    write_changes -format icctcl -output $dir/eco_icc2.tcl
    write_changes -format ptsh   -output $dir/eco_pt.tcl
    # Innovus does not read icctcl; translate size_cell / insert_buffer.
    set fh [open $dir/eco_pt.tcl r]
    set oh [open $dir/eco_innovus.tcl w]
    puts $oh "# Generated from PrimeTime write_changes"
    set n 0
    while {[gets $fh line] >= 0} {
        if {[regexp {^size_cell\s+\{?([^\s\}]+)\}?\s+\{?([^\s\}]+)\}?} $line -> inst lib]} {
            set libcell [lindex [split $lib "/"] end]
            puts $oh "ecoChangeCell -inst $inst -cell $libcell"
            incr n
        } elseif {[regexp {^insert_buffer\s+\{?([^\s\}]+)\}?\s+\{?([^\s\}]+)\}?} $line -> pin lib]} {
            set libcell [lindex [split $lib "/"] end]
            puts $oh "ecoAddRepeater -term $pin -cell $libcell"
            incr n
        }
    }
    close $fh
    close $oh
    puts "exported $n ECO commands to $dir/ (icc2, pt, innovus)"

    # Post-ECO summary for the sign-off note.
    redirect -file $dir/post_eco_qor.rpt { report_qor }
    redirect -file $dir/post_eco_global.rpt { report_global_timing }
}
