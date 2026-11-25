# Portable Vivado batch flow: synthesis, implementation, bitstream & timing/utilization reports
set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ".."]]
set build_dir  [file join $repo_root "build"]
file mkdir $build_dir

set_param general.maxThreads 4
create_project -in_memory -part xc7a100tcsg324-1

set_property include_dirs [list [file join $repo_root "rtl"]] [current_fileset]
foreach f [lsort [glob [file join $repo_root "rtl" "*.v"]]] {
    read_verilog $f
}
foreach h [lsort [glob -nocomplain [file join $repo_root "rtl" "*.vh"]]] {
    add_files -norecurse $h
}
foreach m [lsort [glob [file join $repo_root "mem" "*.mem"]]] {
    add_files -norecurse $m
    set_property file_type {Memory Initialization Files} [get_files $m]
}
read_xdc [file join $repo_root "constrs" "nexys_a7_game_v2.xdc"]

cd $repo_root
synth_design -top drago_nexus_v2_top -part xc7a100tcsg324-1 -directive RuntimeOptimized -flatten_hierarchy none
write_checkpoint -force [file join $build_dir "post_synth.dcp"]

opt_design
place_design
route_design

set bitfile [file join $build_dir "drago_nexus_v2_top.bit"]
write_bitstream -force $bitfile
report_timing_summary -file [file join $repo_root "timing_summary.rpt"]
report_utilization    -file [file join $repo_root "util_summary.rpt"]

puts "=== BITSTREAM READY: $bitfile ==="
close_project
exit
