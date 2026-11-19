set_param general.maxThreads 2
set proj_dir "D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj"
file mkdir $proj_dir

create_project -force drago_nexus_v2 $proj_dir -part xc7a100tcsg324-1

add_files -norecurse [glob D:/vivado_pj/DRAGO_NEXUS_V2/rtl/*.v]
add_files -norecurse [glob -nocomplain D:/vivado_pj/DRAGO_NEXUS_V2/rtl/*.vh]
add_files -norecurse [glob D:/vivado_pj/DRAGO_NEXUS_V2/*.mem]
set_property file_type {Memory Initialization Files} [get_files *.mem]

add_files -fileset constrs_1 -norecurse D:/vivado_pj/DRAGO_NEXUS_V2/constrs/nexys_a7_game_v2.xdc

set_property top drago_nexus_v2_top [current_fileset]
update_compile_order -fileset sources_1

# Prevent Vivado 2024.2 Windows timing-hill-climbing crash during synth_design
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]

# Run Synthesis
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "=== SYNTH STATUS: $synth_status ==="
if {[string match "*ERROR*" $synth_status]} {
    error "Synthesis failed: $synth_status"
}

# Run Implementation + Bitstream Generation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "=== IMPL STATUS: $impl_status ==="
if {[string match "*ERROR*" $impl_status]} {
    error "Implementation/Bitstream failed: $impl_status"
}

# Report Timing & Utilization
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file D:/vivado_pj/DRAGO_NEXUS_V2/timing_summary.rpt
report_utilization -file D:/vivado_pj/DRAGO_NEXUS_V2/util_summary.rpt
set wns [get_property STATS.WNS [get_runs impl_1]]
set whs [get_property STATS.WHS [get_runs impl_1]]
puts "=== TIMING WNS=$wns ns, WHS=$whs ns ==="

set bitfile "$proj_dir/drago_nexus_v2.runs/impl_1/drago_nexus_v2_top.bit"
if {![file exists $bitfile]} {
    error "Bitstream not found at $bitfile"
}
puts "=== BITSTREAM READY: $bitfile ==="

# Program connected Nexys A7-100T FPGA
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices xc7a100t*] 0]
if {$dev eq ""} {
    puts "WARNING: No xc7a100t hardware device detected! Skipping direct programming."
} else {
    current_hw_device $dev
    refresh_hw_device -update_hw_probes false $dev
    set_property PROBES.FILE {} $dev
    set_property FULL_PROBES.FILE {} $dev
    set_property PROGRAM.FILE $bitfile $dev
    program_hw_devices $dev
    refresh_hw_device $dev
    puts "=== PROGRAMMED SUCCESSFULLY ONTO NEXYS A7-100T ==="
}
close_hw_manager
