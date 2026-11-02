// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
// Date        : Tue Jan 14 11:55:29 2025
// Host        : LAPTOP-VF8QDR9E running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top system_up_axi_0_0 -prefix
//               system_up_axi_0_0_ system_up_axi_0_0_stub.v
// Design      : system_up_axi_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z100ffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "up_axi,Vivado 2021.1" *)
module system_up_axi_0_0(up_rstn, up_clk, up_axi_awvalid, up_axi_awaddr, 
  up_axi_awready, up_axi_wvalid, up_axi_wdata, up_axi_wstrb, up_axi_wready, up_axi_bvalid, 
  up_axi_bresp, up_axi_bready, up_axi_arvalid, up_axi_araddr, up_axi_arready, up_axi_rvalid, 
  up_axi_rresp, up_axi_rdata, up_axi_rready, up_wreq, up_waddr, up_wdata, up_wack, up_rreq, 
  up_raddr, up_rdata, up_rack)
/* synthesis syn_black_box black_box_pad_pin="up_rstn,up_clk,up_axi_awvalid,up_axi_awaddr[15:0],up_axi_awready,up_axi_wvalid,up_axi_wdata[31:0],up_axi_wstrb[3:0],up_axi_wready,up_axi_bvalid,up_axi_bresp[1:0],up_axi_bready,up_axi_arvalid,up_axi_araddr[15:0],up_axi_arready,up_axi_rvalid,up_axi_rresp[1:0],up_axi_rdata[31:0],up_axi_rready,up_wreq,up_waddr[15:0],up_wdata[31:0],up_wack,up_rreq,up_raddr[15:0],up_rdata[31:0],up_rack" */;
  input up_rstn;
  input up_clk;
  input up_axi_awvalid;
  input [15:0]up_axi_awaddr;
  output up_axi_awready;
  input up_axi_wvalid;
  input [31:0]up_axi_wdata;
  input [3:0]up_axi_wstrb;
  output up_axi_wready;
  output up_axi_bvalid;
  output [1:0]up_axi_bresp;
  input up_axi_bready;
  input up_axi_arvalid;
  input [15:0]up_axi_araddr;
  output up_axi_arready;
  output up_axi_rvalid;
  output [1:0]up_axi_rresp;
  output [31:0]up_axi_rdata;
  input up_axi_rready;
  output up_wreq;
  output [15:0]up_waddr;
  output [31:0]up_wdata;
  input up_wack;
  output up_rreq;
  output [15:0]up_raddr;
  input [31:0]up_rdata;
  input up_rack;
endmodule
