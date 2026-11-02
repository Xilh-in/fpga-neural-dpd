// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
// Date        : Tue Jan 14 11:55:49 2025
// Host        : LAPTOP-VF8QDR9E running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top system_jesd204_0_2 -prefix
//               system_jesd204_0_2_ system_jesd204_0_2_stub.v
// Design      : system_jesd204_0_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z100ffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "jesd204_v7_2_12,Vivado 2021.1" *)
module system_jesd204_0_2(rx_reset, rx_core_clk, rx_sysref, rx_sync, 
  rx_aresetn, rx_start_of_frame, rx_end_of_frame, rx_start_of_multiframe, 
  rx_end_of_multiframe, rx_frame_error, rx_tvalid, rx_tdata, rx_reset_gt, rxencommaalign_out, 
  rx_reset_done, gt0_rxdata, gt0_rxcharisk, gt0_rxdisperr, gt0_rxnotintable, gt1_rxdata, 
  gt1_rxcharisk, gt1_rxdisperr, gt1_rxnotintable, s_axi_aclk, s_axi_aresetn, s_axi_awaddr, 
  s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, 
  s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_arready, 
  s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready)
/* synthesis syn_black_box black_box_pad_pin="rx_reset,rx_core_clk,rx_sysref,rx_sync,rx_aresetn,rx_start_of_frame[3:0],rx_end_of_frame[3:0],rx_start_of_multiframe[3:0],rx_end_of_multiframe[3:0],rx_frame_error[7:0],rx_tvalid,rx_tdata[63:0],rx_reset_gt,rxencommaalign_out,rx_reset_done,gt0_rxdata[31:0],gt0_rxcharisk[3:0],gt0_rxdisperr[3:0],gt0_rxnotintable[3:0],gt1_rxdata[31:0],gt1_rxcharisk[3:0],gt1_rxdisperr[3:0],gt1_rxnotintable[3:0],s_axi_aclk,s_axi_aresetn,s_axi_awaddr[11:0],s_axi_awvalid,s_axi_awready,s_axi_wdata[31:0],s_axi_wstrb[3:0],s_axi_wvalid,s_axi_wready,s_axi_bresp[1:0],s_axi_bvalid,s_axi_bready,s_axi_araddr[11:0],s_axi_arvalid,s_axi_arready,s_axi_rdata[31:0],s_axi_rresp[1:0],s_axi_rvalid,s_axi_rready" */;
  input rx_reset;
  input rx_core_clk;
  input rx_sysref;
  output rx_sync;
  output rx_aresetn;
  output [3:0]rx_start_of_frame;
  output [3:0]rx_end_of_frame;
  output [3:0]rx_start_of_multiframe;
  output [3:0]rx_end_of_multiframe;
  output [7:0]rx_frame_error;
  output rx_tvalid;
  output [63:0]rx_tdata;
  output rx_reset_gt;
  output rxencommaalign_out;
  input rx_reset_done;
  input [31:0]gt0_rxdata;
  input [3:0]gt0_rxcharisk;
  input [3:0]gt0_rxdisperr;
  input [3:0]gt0_rxnotintable;
  input [31:0]gt1_rxdata;
  input [3:0]gt1_rxcharisk;
  input [3:0]gt1_rxdisperr;
  input [3:0]gt1_rxnotintable;
  input s_axi_aclk;
  input s_axi_aresetn;
  input [11:0]s_axi_awaddr;
  input s_axi_awvalid;
  output s_axi_awready;
  input [31:0]s_axi_wdata;
  input [3:0]s_axi_wstrb;
  input s_axi_wvalid;
  output s_axi_wready;
  output [1:0]s_axi_bresp;
  output s_axi_bvalid;
  input s_axi_bready;
  input [11:0]s_axi_araddr;
  input s_axi_arvalid;
  output s_axi_arready;
  output [31:0]s_axi_rdata;
  output [1:0]s_axi_rresp;
  output s_axi_rvalid;
  input s_axi_rready;
endmodule
