// -----------------------------------------------------------------------------
// Copyright (c) 2014-2024 All rights reserved
// -----------------------------------------------------------------------------
// Author : youkaiyuan v3eduyky@126.com
// Wechat : 15921999232
// File   : jesd204_transport_layer.v
// Create : 2024-03-30 18:46:57
// Revise : 2024-04-15 15:18:32
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------
`timescale  1ns/1ps

module jesd204_transport_layer(
	input 	            rxclk           ,
	input 	            txclk           ,
	input 	            tx_sample_clk   ,

	input [15:0]		    tx1_idata       ,
	input [15:0]		    tx1_qdata       ,
	input [15:0]		    tx2_idata       ,
	input [15:0]		    tx2_qdata       ,

	output [127:0]	    txdata          ,
	input  			        txready         ,

	input 	[63:0]	    rxdata          ,//@122.88M
	input 				      rxvalid         ,
	input 	[63:0]	    orxdata         ,
	input 				      orxvalid        ,

	output 				      rx_dataen       ,
	output 	[15:0]	    rx1_idata       ,
	output 	[15:0]	    rx1_qdata       ,
	output 	[15:0]	    rx2_idata       ,
	output 	[15:0]	    rx2_qdata       ,

  output  reg         orx_en          ,
	output 	[15:0]	    orx1_idata      ,
	output 	[15:0]	    orx1_qdata      ,
	output 	[15:0]	    orx2_idata      ,
	output 	[15:0]	    orx2_qdata      
	);


//tx 4 lanne
wire	[15:0]	  txlane0;
wire 	[15:0]	  txlane1;
wire	[15:0]	  txlane2;
wire 	[15:0]	  txlane3;


wire 			      tx_full;
wire 			      tx_empty;
wire 	[63:0]	  tx_samp_1;
wire	[63:0]	  tx_samp_2;
wire 	[63:0]	  rx_samp_1;
wire 	[63:0] 	  rx_samp_2;

reg [15:0]      rx1_di;
reg [15:0]      rx1_dq;
reg [15:0]      rx2_di;
reg [15:0]      rx2_dq;
reg             rx_en;

reg [15:0]      orx1_di;
reg [15:0]      orx1_dq;
reg [15:0]      orx2_di;
reg [15:0]      orx2_dq;

//assign txlane2 = tx1_idata;
//assign txlane1 = tx1_qdata;
//assign txlane0 = tx2_idata;
//assign txlane3 = tx2_qdata;
assign txlane1 = tx1_idata;
assign txlane2 = tx1_qdata;
assign txlane3 = tx2_idata;
assign txlane0 = tx2_qdata;

txdatafifo64to128 txdatafifo64to128_inst (
  .wr_clk     (tx_sample_clk                    ),        // input wire wr_clk
  .rd_clk     (txclk                            ),        // input wire rd_clk
  .din        ({txlane3,txlane2,txlane1,txlane0}),        // input wire [63 : 0] din
  .wr_en      ((~tx_full)&txready               ),        // input wire wr_en
  .rd_en      (~tx_empty                        ),        // input wire rd_en
  .dout       ({tx_samp_1,tx_samp_2}            ),        // output wire [127 : 0] dout
  .full       (tx_full                          ),        // output wire full
  .empty      (tx_empty                         )         // output wire empty
);

assign txdata[31:0] = {tx_samp_2[7:0],tx_samp_2[15:8],tx_samp_1[7:0],tx_samp_1[15:8]};
assign txdata[63:32] = {tx_samp_2[23:16],tx_samp_2[31:24],tx_samp_1[23:16],tx_samp_1[31:24]};
assign txdata[95:64] = {tx_samp_2[39:32],tx_samp_2[47:40],tx_samp_1[39:32],tx_samp_1[47:40]};
assign txdata[127:96] = {tx_samp_2[55:48],tx_samp_2[63:56],tx_samp_1[55:48],tx_samp_1[63:56]};


//jesd204_transport_layer demapper
always @(posedge rxclk)
if(rxvalid)
  begin
    rx_en<=1'b1;
    rx1_di <= {rxdata[ 7: 0],rxdata[15: 8]};
    rx1_dq <= {rxdata[23:16],rxdata[31:24]};
    rx2_di <= {rxdata[39:32],rxdata[47:40]};
    rx2_dq <= {rxdata[55:48],rxdata[63:56]};
  end
else
  begin
    rx_en  <= 1'b0;
    rx1_di <= 16'd0;
    rx1_dq <= 16'd0;
    rx2_di <= 16'd0;
    rx2_dq <= 16'd0;
  end

assign rx_dataen = rx_en;
assign rx1_idata = rx1_di;
assign rx1_qdata = rx1_dq;
assign rx2_idata = rx2_di;
assign rx2_qdata = rx2_dq;

assign orx1_idata = orx1_di;
assign orx1_qdata = orx1_dq;
assign orx2_idata = orx2_di;
assign orx2_qdata = orx2_dq;


always @(posedge rxclk)
if(orxvalid)
  begin
    orx_en<=1'b1;
    orx1_di <= {orxdata[ 7: 0],orxdata[15: 8]};
    orx1_dq <= {orxdata[23:16],orxdata[31:24]};
    orx2_di <= {orxdata[39:32],orxdata[47:40]};
    orx2_dq <= {orxdata[55:48],orxdata[63:56]};
  end
else
  begin
    orx_en  <=  1'b0;
    orx1_di <= 16'd0;
    orx1_dq <= 16'd0;
    orx2_di <= 16'd0;
    orx2_dq <= 16'd0;
  end

endmodule
