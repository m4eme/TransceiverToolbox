# Add 1 extra AXI master ports to the interconnect
set_property -dict [list CONFIG.NUM_MI {17}] [get_bd_cells axi_cpu_interconnect]
#connect_bd_net [get_bd_pins axi_cpu_interconnect/M16_ARESETN] [get_bd_pins sys_rstgen/peripheral_aresetn]
#connect_bd_net -net [get_bd_nets axi_adrv9009_rx_clkgen] [get_bd_pins axi_cpu_interconnect/M16_ACLK] [get_bd_pins axi_adrv9009_rx_clkgen/clk_0]
#connect_bd_net [get_bd_pins sys_rstgen/interconnect_aresetn] [get_bd_pins axi_cpu_interconnect/M16_ARESETN]
