# read design sources
read_verilog -v "./rtl/system.v"
read_verilog -v "./rtl/core.v"
read_verilog -v "./rtl/decode.v"
read_verilog -v "./rtl/execute.v"
read_verilog -v "./rtl/alu.v"
read_verilog -v "./rtl/lsu.v"
read_verilog -v "./rtl/csr.sv"
read_verilog -v "./rtl/timer.v"
read_verilog -v "./rtl/regfile.sv"
read_verilog -v "./rtl/uart.sv"
read_verilog -v "./rtl/pram.sv"
read_verilog -v "./rtl/urom.sv"
read_verilog -v "./rtl/sync_fifo.v"
read_verilog -v "./rtl/gpio.v"
read_verilog -v "./rtl/axilt_master.sv"
read_verilog -v "./rtl/axilt_sram_slave.sv"
read_verilog -v "./rtl/axilt_urom_slave.sv"
read_verilog -v "./rtl/axilt_interconnect.sv"
read_verilog -v "./rtl/axilt_interconnect_wrapper.sv"

# read memory sources
read_mem -q "./sw/image.hex"

# read constraints
read_xdc "arty.xdc"

# synth
synth_design -top "system" -part "xc7a35tcpg236-1"

# Optimize design for area
opt_design -directive ExploreArea

# Place design with area optimization
place_design -directive ExtraPostPlacementOpt

# route
route_design

# util report
report_utilization -file build/synth/reports/utilization

report_utilization -hierarchical -file build/synth/reports/hierarchical_utilization

#write bitstream
write_bitstream -force "build/bit/top.bit"

