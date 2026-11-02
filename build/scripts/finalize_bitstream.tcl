# Run in Vivado with the final routed design open.
if {[llength [get_cells -hier -quiet -filter {IS_BLACKBOX == 1}]] != 0} {
    error "Unresolved blackboxes remain."
}
foreach delay_type {max min} {
    set paths [get_timing_paths -quiet -delay_type $delay_type -max_paths 1]
    if {[llength $paths] == 0} {error "No $delay_type timing path found."}
    if {[get_property SLACK [lindex $paths 0]] < 0} {
        error "Negative $delay_type slack; finish timing optimization before bit generation."
    }
}
set root [file normalize [file join [file dirname [info script]] ../..]]
set out [file join $root build generated [clock format [clock seconds] -format {%Y%m%d_%H%M%S}]]
file mkdir $out
report_timing_summary -file [file join $out timing_summary.rpt]
report_route_status -file [file join $out route_status.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint [file join $out timing_checked.dcp]
write_bitstream [file join $out dpd_align_fix.bit]
puts "OUTPUT_DIR=$out"
