# Fast program-only script using existing built bitstream
set bitfile "D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/drago_nexus_v2_top.bit"
if {![file exists $bitfile]} {
    error "Bitstream not found at $bitfile"
}
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices xc7a100t*] 0]
if {$dev eq ""} {
    error "No xc7a100t hardware device detected!"
}
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
set_property PROBES.FILE {} $dev
set_property FULL_PROBES.FILE {} $dev
set_property PROGRAM.FILE $bitfile $dev
program_hw_devices $dev
refresh_hw_device $dev
puts "=== PROGRAMMED SUCCESSFULLY ==="
close_hw_manager
