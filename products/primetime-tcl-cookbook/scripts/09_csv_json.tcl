#-----------------------------------------------------------------------
# File    : 09_csv_json.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : CSV and JSON writers in pure Tcl (no packages needed)
# Tool    : PrimeTime (pt_shell) or any Tcl 8.x
# Usage   : source 09_csv_json.tcl
#-----------------------------------------------------------------------

# CSV: quote a field if it contains a comma, quote, or newline.
proc csv_field {v} {
    if {[regexp {[",\n]} $v]} {
        return "\"[string map {\" \"\"} $v]\""
    }
    return $v
}

proc csv_row {fields} {
    set out {}
    foreach f $fields { lappend out [csv_field $f] }
    return [join $out ","]
}

# Writes header (list) and rows (list of lists) to a file.
proc write_csv {file header rows} {
    set fh [open $file w]
    puts $fh [csv_row $header]
    foreach r $rows { puts $fh [csv_row $r] }
    close $fh
}

# Reads a CSV back into a list of lists (simple: no embedded newlines).
proc read_csv {file} {
    set fh [open $file r]
    set rows {}
    while {[gets $fh line] >= 0} {
        if {$line eq ""} { continue }
        set fields {}
        set cur ""
        set inq 0
        for {set i 0} {$i < [string length $line]} {incr i} {
            set ch [string index $line $i]
            if {$inq} {
                if {$ch eq "\"" && [string index $line [expr {$i+1}]] eq "\""} {
                    append cur "\""; incr i
                } elseif {$ch eq "\""} {
                    set inq 0
                } else {
                    append cur $ch
                }
            } else {
                if {$ch eq "\""} { set inq 1 } \
                elseif {$ch eq ","} { lappend fields $cur; set cur "" } \
                else { append cur $ch }
            }
        }
        lappend fields $cur
        lappend rows $fields
    }
    close $fh
    return $rows
}

# JSON helpers. Values are emitted as numbers when they look numeric.
proc json_str {s} {
    set s [string map {\\ \\\\ \" \\\" \n \\n \t \\t \r \\r} $s]
    return "\"$s\""
}

proc json_val {v} {
    if {[string is double -strict $v] && ![string match "0?*" $v]} { return $v }
    if {$v eq "true" || $v eq "false"} { return $v }
    return [json_str $v]
}

# dict -> JSON object (one level; nested values must already be JSON)
proc json_obj {kv {raw_keys {}}} {
    set parts {}
    foreach {k v} $kv {
        if {[lsearch -exact $raw_keys $k] >= 0} {
            lappend parts "[json_str $k]: $v"
        } else {
            lappend parts "[json_str $k]: [json_val $v]"
        }
    }
    return "\{[join $parts ", "]\}"
}

proc json_arr {items {raw 0}} {
    set parts {}
    foreach i $items {
        if {$raw} { lappend parts $i } else { lappend parts [json_val $i] }
    }
    return "\[[join $parts ", "]\]"
}

# Rows (list of lists) + header -> JSON array of objects, written to file.
proc write_json_rows {file header rows} {
    set objs {}
    foreach r $rows {
        set kv {}
        foreach h $header v $r { lappend kv $h $v }
        lappend objs [json_obj $kv]
    }
    set fh [open $file w]
    puts $fh [json_arr $objs 1]
    close $fh
}
