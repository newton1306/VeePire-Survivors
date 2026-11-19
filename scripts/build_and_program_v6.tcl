# In-memory full synthesis, implementation, bitstream, reports & immediate JTAG FPGA flash for V6
set_param general.maxThreads 1
create_project -in_memory -part xc7a100tcsg324-1
set_property include_dirs {D:/vivado_pj/DRAGO_NEXUS_V2/rtl} [current_fileset]
foreach f [glob D:/vivado_pj/DRAGO_NEXUS_V2/rtl/*.v] {
    read_verilog $f
}
foreach h [glob -nocomplain D:/vivado_pj/DRAGO_NEXUS_V2/rtl/*.vh] {
    add_files -norecurse $h
}
foreach m [glob D:/vivado_pj/DRAGO_NEXUS_V2/*.mem] {
    add_files -norecurse $m
    set_property file_type {Memory Initialization Files} [get_files $m]
}
read_xdc D:/vivado_pj/DRAGO_NEXUS_V2/constrs/nexys_a7_game_v2.xdc

cd D:/vivado_pj/DRAGO_NEXUS_V2
synth_design -top drago_nexus_v2_top -part xc7a100tcsg324-1 -directive RuntimeOptimized -flatten_hierarchy none
file mkdir D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1
write_checkpoint -force D:/vivado_pj/DRAGO_NEXUS_V2/vivado_proj/drago_nexus_v2.runs/impl_1/post_synth.dcp
puts "=== V6 SYNTH CHECKPOINT SAVED ==="
close_project
exit
