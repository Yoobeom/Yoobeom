#-----------------------------------------------------------------------
# File    : 03_list_attrs.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Dump every attribute of one object for discovery
# Tool    : PrimeTime (pt_shell)
# Usage   : source 03_list_attrs.tcl ; dump_attrs [get_cells U1]
#-----------------------------------------------------------------------

# Prints name = value for every defined attribute of the object class.
# Use it once per class when writing a new recipe, then hard-code the
# attribute names you need.
proc dump_attrs {obj {class ""}} {
    if {$class eq ""} { set class [get_attribute $obj object_class] }
    redirect -variable txt { list_attributes -application -class $class }
    set names {}
    foreach line [split $txt "\n"] {
        # attribute table rows start with the attribute name
        if {[regexp {^([a-z][a-z0-9_]+)\s+(\S+)\s+(\S+)} $line -> name type cls]} {
            lappend names $name
        }
    }
    puts "class=$class object=[get_object_name $obj] ([llength $names] attributes)"
    foreach n [lsort $names] {
        set v [get_attribute -quiet $obj $n]
        if {$v ne ""} {
            # collections print as handles, show their size instead
            if {[string match "_sel*" $v]} { set v "<collection [sizeof_collection $v]>" }
            puts [format "  %-45s = %s" $n $v]
        }
    }
}
