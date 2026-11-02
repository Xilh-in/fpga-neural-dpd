// -----------------------------------------------------------------------------
// Copyright (c) 2014-2024 All rights reserved
// -----------------------------------------------------------------------------
// Author : youkaiyuan v3eduyky@126.com
// Wechat : 15921999232
// File   : jesd204b_adc_dac_top.v
// Create : 2024-03-25 16:41:50
// Revise : 2024-03-31 10:55:37
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------
`timescale  1ns/1ps
`timescale 1ns / 1ps

module jesd204b_adc_dac_top(
  //SYNC
  output                  rx_sync_p         ,
  output                  rx_sync_n         ,
  output                  rx_os_sync_p      ,
  output                  rx_os_sync_n      ,
  input                   tx_sync_p         ,
  input                   tx_sync_n         ,
  //SYSREF
	input	                  sysref_n          ,
	input 	                sysref_p          ,
  //DATA
	input	  [3:0]	          rxn_in            ,
	input 	[3:0]	          rxp_in            ,
	output 	[3:0]	          txn_out           ,
	output 	[3:0]	          txp_out           ,
  //CLK
	input 			            cpll_refclk_p     ,
	input 			            cpll_refclk_n     ,
	input	  		            qpll_refclk_p     ,
	input 			            qpll_refclk_n     ,
  //SPI
  inout                   spi_csn_ad9528    ,
  inout                   spi_csn_ad9371    ,
  output                  spi_clk           ,
  output                  spi_mosi          ,
  input                   spi_miso          ,
  //GPIO
  inout                   ad9528_reset_b    ,
  inout                   ad9528_sysref_req ,
  inout                   ad9371_tx1_enable ,
  inout                   ad9371_tx2_enable ,
  inout                   ad9371_rx1_enable ,
  inout                   ad9371_rx2_enable ,
  inout                   ad9371_test       ,
  inout                   ad9371_reset_b    ,
  inout                   ad9371_gpint         
);
  
/*********************function**************************/

/*********************parameter*************************/

/***********************port****************************/

/***********************mechine*************************/

/************************reg****************************/

/************************wire***************************/
//CLK
wire          cpll_refclk;
wire          fpga_gc_clk;
wire          qpll_refclk;

//jesd204b transfor_layer
wire [127:0]  rx_tdata;
wire          rx_tvalid;
wire          orx_tvalid;

wire [127:0]  tx_tdata;
wire          tx_tready;
wire          txoutclk;
wire          tx_sample_clk;
wire          rx_sample_clk;

//transfor_layer data
wire [15:0]		rx1_idata;
wire [15:0]		rx1_qdata;
wire [15:0]		rx2_idata;
wire [15:0]		rx2_qdata;

wire [15:0]		orx1_idata;
wire [15:0]		orx1_qdata;
wire [15:0]		orx2_idata;
wire [15:0]		orx2_qdata;


wire [15:0]		tx1_idata;
wire [15:0]		tx1_qdata;
wire [15:0]		tx2_idata;
wire [15:0]		tx2_qdata;

//gpio
wire [10:0]    gpio_i;
wire [10:0]    gpio_o;
wire [10:0]    gpio_t;

//register defination
wire          config_done;

//axi lite drv config
wire          up_rack;
wire [15:0]   up_raddr;
wire [31:0]   up_rdata;
wire          up_rreq;
wire          up_wack;
wire [15:0]   up_waddr;
wire [31:0]   up_wdata;
wire          up_wreq;

wire          fclk_100m;
wire          fclk_resetn;
wire          jesd204b_reset;

//axi lite dpd config
wire           dpd_wreq  ;
wire [  15: 0] dpd_waddr ;
wire [  31: 0] dpd_wdata ;
wire           dpd_wack  ;
wire           dpd_rreq  ;
wire [  15: 0] dpd_raddr ;
wire [  31: 0] dpd_rdata ;
wire           dpd_rack  ;


//sync
wire          tx_sync;
wire          rx_sync;
wire          orx_sync;


/*********************component*************************/
//cpll鏃堕挓宸垎杞崟绔?
IBUFDS_GTE2 i_ibufds_ref_clk0 (
  .CEB    (1'b0           ),
  .I      (cpll_refclk_p  ),
  .IB     (cpll_refclk_n  ),
  .O      (cpll_refclk    ),
  .ODIV2  (               )
);
  
//qpll鏃堕挓宸垎杞崟绔?
IBUFDS_GTE2 i_ibufds_ref_clk1 (
  .CEB    (1'b0           ),
  .I      (qpll_refclk_p  ),
  .IB     (qpll_refclk_n  ),
  .O      (qpll_refclk    ),
  .ODIV2  (               )
);

//gc_clk澶嶅埗REF_CLK
BUFG i_bufg_ref_clk (
  .I      (qpll_refclk    ),
  .O      (fpga_gc_clk    )
);

//sysref杈撳叆宸垎杞崟绔?     
IBUFDS i_ibufds_sysref (
  .I    (sysref_p         ),
  .IB   (sysref_n         ),
  .O    (sysref           )
);

IBUFDS i_ibufds_txsync (
  .I    (tx_sync_p        ),
  .IB   (tx_sync_n        ),
  .O    (tx_sync          )
);

OBUFDS  OBUFDS_rxsync (
  .O    (rx_sync_p        ),    
  .OB   (rx_sync_n        ), 
  .I    (rx_sync          )     
);

OBUFDS  OBUFDS_orxsync (
  .O    (rx_os_sync_p     ),    
  .OB   (rx_os_sync_n     ),   
  .I    (orx_sync         )     
);



ad_iobuf #(.DATA_WIDTH(11)) i_iobuf (
    .dio_t ({gpio_t[10:0]}),
    .dio_i ({gpio_o[10:0]}),
    .dio_o ({gpio_i[10:0]}),
    .dio_p ({ 
              spi_csn_ad9371,
              spi_csn_ad9528,
              ad9528_reset_b,       // 59
              ad9528_sysref_req,    // 58
              ad9371_tx1_enable,    // 57
              ad9371_tx2_enable,    // 56
              ad9371_rx1_enable,    // 55
              ad9371_rx2_enable,    // 54
              ad9371_test,          // 53
              ad9371_reset_b,       // 52
              ad9371_gpint          // 51 
              })
);   

//block design
system_wrapper system_wrapper_inst(
        .cpll_refclk        (cpll_refclk    ),
        .fpga_gc_clk        (fpga_gc_clk    ),
        .jesd204b_reset     (jesd204b_reset ),
        .qpll_refclk        (qpll_refclk    ),

        .tx_sync            (tx_sync        ),
        .rx_sync            (rx_sync        ),
        .orx_sync           (orx_sync       ),
        .orx_tdata          (orx_tdata      ),
        .orx_tvalid         (orx_tvalid     ),

        .rx_tdata           (rx_tdata       ),
        .rx_tvalid          (rx_tvalid      ),
        .rxn_in             (rxn_in         ),
        .rxp_in             (rxp_in         ),
        .sysref             (sysref         ),
        .tx_tdata           (tx_tdata       ),
        .tx_tready          (tx_tready      ),
        .txn_out            (txn_out        ),
        .txout_clk          (txoutclk       ),
        .txp_out            (txp_out        ),
        .rx_sample_clk      (rx_sample_clk  ),
        .tx_sample_clk      (tx_sample_clk  ),

        .up_rack            (up_rack        ),
        .up_raddr           (up_raddr       ),
        .up_rdata           (up_rdata       ),
        .up_rreq            (up_rreq        ),
        .up_wack            (up_wack        ),
        .up_waddr           (up_waddr       ),
        .up_wdata           (up_wdata       ),
        .up_wreq            (up_wreq        ),
        
        .dpd_rack           (dpd_rack       ),
        .dpd_raddr          (dpd_raddr      ),
        .dpd_rdata          (dpd_rdata      ),
        .dpd_rreq           (dpd_rreq       ),
        .dpd_wack           (dpd_wack       ),
        .dpd_waddr          (dpd_waddr      ),
        .dpd_wdata          (dpd_wdata      ),
        .dpd_wreq           (dpd_wreq       ),

        .GPIO_I             (gpio_i         ),
        .GPIO_O             (gpio_o         ),
        .GPIO_T             (gpio_t         ),
        .SPI0_MISO_I        (spi_miso       ),
        .SPI0_MOSI_O        (spi_mosi       ),
        .SPI0_SCLK_O        (spi_clk        ),
        .fclk_100m          (fclk_100m      ),
        .fclk_resetn        (fclk_resetn    )
  );


//JESD鏀跺彂鐢ㄦ埛灞傚畬鎴愭暟鎹畝鍗曠紪鐮?
jesd204_transport_layer inst_jesd204_transport_layer
  (
    .rxclk              (rx_sample_clk      ),
    .txclk              (txoutclk           ),
    .tx_sample_clk      (tx_sample_clk      ),

    .tx1_idata          (tx1_idata          ),
    .tx1_qdata          (tx1_qdata          ),
    .tx2_idata          (tx2_idata          ),
    .tx2_qdata          (tx2_qdata          ),
    .rx1_idata          (rx1_idata          ),
    .rx1_qdata          (rx1_qdata          ),
    .rx2_idata          (rx2_idata          ),
    .rx2_qdata          (rx2_qdata          ),
	  .orx1_idata         (orx1_idata         ),
	  .orx1_qdata         (orx1_qdata         ),
	  .orx2_idata         (orx2_idata         ),
	  .orx2_qdata         (orx2_qdata         ),
    
    .txdata             (tx_tdata           ),
    .txready            (tx_tready          ),

    .rxdata             (rx_tdata           ),
    .orxdata            (orx_tdata          ),

    .orxvalid 		      (orx_tvalid         ),
    .rxvalid            (rx_tvalid          )
  );


axi_lite_drv axi_lite_drv(
  .axi_gp_clk           (fclk_100m          ),//global
  .axi_rst_n            (fclk_resetn        ),

  .up_rack              (up_rack            ),
  .up_raddr             (up_raddr           ),
  .up_rdata             (up_rdata           ),
  .up_rreq              (up_rreq            ),
  .up_wack              (up_wack            ),
  .up_waddr             (up_waddr           ),
  .up_wdata             (up_wdata           ),
  .up_wreq              (up_wreq            ),

  .mtime_start          (            ),
  .phase                (            ),
  .rf_mode              (            ),
  .jesd204_reset        (jesd204b_reset     ),
  .rf1_gpio_t           (         ),
  .rf1_gpio_o           (         ),
  .rf1_gpio_i           (         ),
  .sdr_info             (         ),
  .config_done          (config_done        )
);



axi_lite_dpd u_axi_lite_dpd(
//global
    .axi_gp_clk                         (fclk_100m                ),
    .axi_rst_n                          (fclk_resetn              ),
// AXI Lite Master Interface connections
    .up_wreq                            (dpd_wreq                  ),
    .up_waddr                           (dpd_waddr                 ),
    .up_wdata                           (dpd_wdata                 ),
    .up_wack                            (dpd_wack                  ),
    .up_rreq                            (dpd_rreq                  ),
    .up_raddr                           (dpd_raddr                 ),
    .up_rdata                           (dpd_rdata                 ),
    .up_rack                            (dpd_rack                  ),
//register tx
    .tx_sample_clk                      (tx_sample_clk             ),
    .tx1_idata                          (tx1_idata                 ),
    .tx1_qdata                          (tx1_qdata                 ),
    .tx2_idata                          (tx2_idata                 ),
    .tx2_qdata                          (tx2_qdata                 ),
//register rx
    .rx_sample_clk                      (rx_sample_clk             ),
    .rx1_idata                          (rx1_idata                 ),
    .rx1_qdata                          (rx1_qdata                 ),
    .rx2_idata                          (rx2_idata                 ),
    .rx2_qdata                          (rx2_qdata                 ) 
);



/***********************assign**************************/

/***********************always**************************/


/***********************sim&ILA**************************/


//妯℃嫙浜х敓IQ鏁版嵁
// assign tx2_idata = tx1_idata;
// assign tx2_qdata = tx1_qdata;

// //DDS
// DDS_Channel1 DDS_Channel1_U (
//   .aclk               (tx_sample_clk        ),  
//   .m_axis_data_tvalid (m_axis_data_tvalid_1 ),
//   .m_axis_data_tdata  ({tx1_qdata,tx1_idata})   
// );


// DDS_Channel2 DDS_Channel2_U (
//   .aclk               (tx_sample_clk        ),  
//   .m_axis_data_tvalid (m_axis_data_tvalid_2 ),
//   .m_axis_data_tdata  ({tx2_qdata,tx2_idata})   
// );

ila_adc ila_rx_inst (
  .clk(rx_sample_clk),        // input wire clk
  .probe0({
    rx1_idata ,
    rx2_idata ,
    rx1_qdata ,
    rx2_qdata ,
    rx_tvalid ,
    sysref    
  })                   // input wire [127:0] probe0
);

ila_adc ila_orx_inst (
  .clk(rx_sample_clk),        // input wire clk
  .probe0({
    orx1_idata ,
    orx2_idata ,
    orx1_qdata ,
    orx2_qdata ,
    orx_tvalid ,
    sysref    
  })                   // input wire [127:0] probe0
);

//ila_adc ila_tx_inst (
//  .clk(tx_sample_clk),        // input wire clk
//  .probe0({
//    tx1_idata ,
//    tx2_idata ,
//    tx1_qdata ,
//    tx2_qdata ,
//    tx_tready ,
//    sysref    
//  })                   // input wire [127:0] probe0
//);

endmodule
