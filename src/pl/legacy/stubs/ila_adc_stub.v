// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
// Date        : Tue Jan 14 12:04:18 2025
// Host        : LAPTOP-VF8QDR9E running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/FPGA_Project/RK7100_LNA/RK7100_LNA.gen/sources_1/ip/ila_adc/ila_adc_stub.v
// Design      : ila_adc
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z100ffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2021.1" *)
module ila_adc(clk, probe0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[127:0]" */;
  input clk;
  input [127:0]probe0;
endmodule
