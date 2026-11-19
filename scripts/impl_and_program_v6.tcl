# Phase 2: Load post_synth.dcp in clean Vivado process -> impl, bitstream, reports & immediate JTAG flash
set_param general.maxThreads 1
cd D:/vivado_pj/DRAGO_NEXUS_V2
open_checkpoint D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/post_synth.dcp
opt_design
place_design
route_design

set bitfile "D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/drago_nexus_v2_top.bit"
write_bitstream -force $bitfile
report_timing_summary -file D:/vivado_pj/DRAGO_NEXUS_V2/timing_summary.rpt
report_utilization    -file D:/vivado_pj/DRAGO_NEXUS_V2/util_summary.rpt
puts "=== V6 BITSTREAM READY: $bitfile ==="

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
puts "=== V6 FPGA PROGRAMMED SUCCESSFULLY ==="
close_hw_manager
exit
