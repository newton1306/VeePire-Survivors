open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
puts "TARGETS: [get_hw_targets]"
puts "DEVICES: [get_hw_devices]"
close_hw_manager
exit