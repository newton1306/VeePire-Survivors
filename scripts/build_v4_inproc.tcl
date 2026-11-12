set_param general.maxThreads 1
create_project -in_memory -part xc7a100tcsg324-1
foreach f [glob D:/vivado_pj/DRAGO_NEXUS_V2/rtl/*.v] {
    read_verilog $f
}
foreach m [glob D:/vivado_pj/DRAGO_NEXUS_V2/mem/*.mem] {
    add_files -norecurse $m
    set_property file_type {Memory Initialization Files} [get_files $m]
}
read_xdc D:/vivado_pj/DRAGO_NEXUS_V2/constrs/nexys_a7_game_v2.xdc

cd D:/vivado_pj/DRAGO_NEXUS_V2/mem
synth_design -top drago_nexus_v2_top -part xc7a100tcsg324-1 -directive RuntimeOptimized
opt_design
place_design
route_design

file mkdir D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1
write_bitstream -force D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/drago_nexus_v2_top.bit
report_timing_summary -file D:/vivado_pj/DRAGO_NEXUS_V2/timing_summary.rpt
report_utilization    -file D:/vivado_pj/DRAGO_NEXUS_V2/util_summary.rpt
puts "=== IN-PROCESS BITSTREAM READY: D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/drago_nexus_v2_top.bit ==="
