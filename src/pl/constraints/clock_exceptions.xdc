set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks clk_out2_system_clk_wiz_0_0]
set_false_path -from [get_clocks clk_out2_system_clk_wiz_0_0] -to [get_clocks clk_fpga_0]
set_clock_groups -name ps_jesd_tx_async -asynchronous \
    -group [get_clocks clk_fpga_0] \
    -group [get_clocks clk_out1_system_clk_wiz_0_0]