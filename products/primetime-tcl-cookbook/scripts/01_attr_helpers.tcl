#-----------------------------------------------------------------------
# File    : 01_attr_helpers.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Safe attribute access helpers (INFINITY / empty / missing)
# Tool    : PrimeTime (pt_shell)
# Usage   : source 01_attr_helpers.tcl
#-----------------------------------------------------------------------

# Returns the attribute value or a default if the attribute is missing,
# empty, or non-numeric (INFINITY, UNCONSTRAINED, etc).
proc attr_num {obj attr {default 0.0}} {
    set v [get_attribute -quiet $obj $attr]
    if {$v eq "" || ![string is double -strict $v]} {
        return $default
    }
    return $v
}

# Returns the attribute as a string, "" when missing.
proc attr_str {obj attr} {
    return [get_attribute -quiet $obj $attr]
}

# Returns the leaf name of an object (last path element).
proc leaf_name {obj} {
    return [lindex [split [get_object_name $obj] "/"] end]
}

# Returns the hierarchical prefix up to depth N.
# hier_prefix u_top/u_core/u_alu/x_reg 2  ->  u_top/u_core
proc hier_prefix {name depth} {
    set parts [split $name "/"]
    if {[llength $parts] <= $depth} {
        return [join [lrange $parts 0 end-1] "/"]
    }
    return [join [lrange $parts 0 [expr {$depth - 1}]] "/"]
}

# Formats a number with fixed decimals; passes strings (INFINITY) through.
proc fmt {v {digits 3}} {
    if {[string is double -strict $v]} {
        return [format "%.${digits}f" $v]
    }
    return $v
}

# Elapsed-time stamp for log lines.
proc ts {} {
    return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
}

proc log_msg {msg} {
    puts "\[[ts]\] $msg"
}
