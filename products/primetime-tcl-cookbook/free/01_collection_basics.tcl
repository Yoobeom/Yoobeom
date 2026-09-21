#-----------------------------------------------------------------------
# File    : 01_collection_basics.tcl
# Author  : yoobeom.kim@samsung.com
# Purpose : Collection handling patterns that every other recipe relies on
# Tool    : PrimeTime (pt_shell)
# Usage   : source 01_collection_basics.tcl
#-----------------------------------------------------------------------

# A collection is a handle, not a list. Never treat it as a Tcl list.
set regs [all_registers -clock_pins]
puts "clock pins : [sizeof_collection $regs]"

# Iterate with foreach_in_collection, never with foreach.
set n 0
foreach_in_collection pin $regs {
    incr n
    if {$n > 3} { break }
    puts [get_object_name $pin]
}

# Convert a small collection to a Tcl list of names when you must.
set names [get_object_name [index_collection $regs 0]]
set name_list {}
foreach_in_collection p $regs { lappend name_list [get_object_name $p] }
puts "list length : [llength $name_list]"

# Combine and subtract.
set seq  [get_cells -hierarchical -filter "is_sequential == true"]
set icg  [get_cells -hierarchical -filter "is_integrated_clock_gating_cell == true"]
set flops [remove_from_collection $seq $icg]
set both  [add_to_collection $flops $icg -unique]
puts "seq=[sizeof_collection $seq] icg=[sizeof_collection $icg] flops=[sizeof_collection $flops]"

# Filter after the fact.
set big_flops [filter_collection $flops "area > 2.0"]

# Sort by attribute (ascending by default).
set worst_first [sort_collection [get_timing_paths -max_paths 50] slack]

# Empty-collection test: an empty collection is the empty string.
set c [get_cells -quiet U_DOES_NOT_EXIST]
if {$c eq ""} { puts "empty collection" }

# Membership test without a loop.
set target [get_pins -quiet u_core/u_alu/reg_q_reg_0_/D]
if {$target ne "" && [sizeof_collection [compare_collections -intersect $regs $target]] > 0} {
    puts "target is a register clock pin"
}
