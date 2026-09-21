#-----------------------------------------------------------------------
# File    : 01_args_parser.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Keyword argument parsing for reusable procs
# Tool    : PrimeTime (pt_shell) or any Tcl 8.x
# Usage   : source 01_args_parser.tcl
#-----------------------------------------------------------------------

# parse_args converts "-key value" pairs into an array.
# defaults is a list of key/value pairs; unknown keys raise an error.
#
#   proc my_report {args} {
#       parse_args opt {-group * -max_paths 100 -out ""} $args
#       puts $opt(-group)
#   }
proc parse_args {arr_name defaults arglist} {
    upvar 1 $arr_name opt
    array set opt $defaults
    for {set i 0} {$i < [llength $arglist]} {incr i} {
        set key [lindex $arglist $i]
        if {![info exists opt($key)]} {
            error "unknown option '$key'. Valid: [array names opt]"
        }
        incr i
        if {$i >= [llength $arglist]} {
            error "option '$key' requires a value"
        }
        set opt($key) [lindex $arglist $i]
    }
}

# Boolean flags: "-verbose" alone, no value.
proc has_flag {arglist flag} {
    return [expr {[lsearch -exact $arglist $flag] >= 0}]
}

proc strip_flag {arglist flag} {
    set idx [lsearch -exact $arglist $flag]
    if {$idx < 0} { return $arglist }
    return [lreplace $arglist $idx $idx]
}
