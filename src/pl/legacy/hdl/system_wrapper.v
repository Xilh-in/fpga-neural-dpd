//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
//Date        : Fri Jan 17 02:12:51 2025
//Host        : LAPTOP-VF8QDR9E running 64-bit major release  (build 9200)
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    GPIO_I,
    GPIO_O,
    GPIO_T,
    SPI0_MISO_I,
    SPI0_MOSI_O,
    SPI0_SCLK_O,
    cpll_refclk,
    dpd_rack,
    dpd_raddr,
    dpd_rdata,
    dpd_rreq,
    dpd_wack,
    dpd_waddr,
    dpd_wdata,
    dpd_wreq,
    fclk_100m,
    fclk_resetn,
    fpga_gc_clk,
    jesd204b_reset,
    orx_sync,
    orx_tdata,
    orx_tvalid,
    qpll_refclk,
    rx_sample_clk,
    rx_sync,
    rx_tdata,
    rx_tvalid,
    rxn_in,
    rxp_in,
    sysref,
    tx_sample_clk,
    tx_sync,
    tx_tdata,
    tx_tready,
    txn_out,
    txout_clk,
    txp_out,
    up_rack,
    up_raddr,
    up_rdata,
    up_rreq,
    up_wack,
    up_waddr,
    up_wdata,
    up_wreq);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input [10:0]GPIO_I;
  output [10:0]GPIO_O;
  output [10:0]GPIO_T;
  input SPI0_MISO_I;
  output SPI0_MOSI_O;
  output SPI0_SCLK_O;
  input cpll_refclk;
  input dpd_rack;
  output [15:0]dpd_raddr;
  input [31:0]dpd_rdata;
  output dpd_rreq;
  input dpd_wack;
  output [15:0]dpd_waddr;
  output [31:0]dpd_wdata;
  output dpd_wreq;
  output fclk_100m;
  output fclk_resetn;
  input fpga_gc_clk;
  input jesd204b_reset;
  output orx_sync;
  output [63:0]orx_tdata;
  output orx_tvalid;
  input qpll_refclk;
  output rx_sample_clk;
  output rx_sync;
  output [63:0]rx_tdata;
  output rx_tvalid;
  input [3:0]rxn_in;
  input [3:0]rxp_in;
  input sysref;
  output tx_sample_clk;
  input tx_sync;
  input [127:0]tx_tdata;
  output tx_tready;
  output [3:0]txn_out;
  output txout_clk;
  output [3:0]txp_out;
  input up_rack;
  output [15:0]up_raddr;
  input [31:0]up_rdata;
  output up_rreq;
  input up_wack;
  output [15:0]up_waddr;
  output [31:0]up_wdata;
  output up_wreq;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [10:0]GPIO_I;
  wire [10:0]GPIO_O;
  wire [10:0]GPIO_T;
  wire SPI0_MISO_I;
  wire SPI0_MOSI_O;
  wire SPI0_SCLK_O;
  wire cpll_refclk;
  wire dpd_rack;
  wire [15:0]dpd_raddr;
  wire [31:0]dpd_rdata;
  wire dpd_rreq;
  wire dpd_wack;
  wire [15:0]dpd_waddr;
  wire [31:0]dpd_wdata;
  wire dpd_wreq;
  wire fclk_100m;
  wire fclk_resetn;
  wire fpga_gc_clk;
  wire jesd204b_reset;
  wire orx_sync;
  wire [63:0]orx_tdata;
  wire orx_tvalid;
  wire qpll_refclk;
  wire rx_sample_clk;
  wire rx_sync;
  wire [63:0]rx_tdata;
  wire rx_tvalid;
  wire [3:0]rxn_in;
  wire [3:0]rxp_in;
  wire sysref;
  wire tx_sample_clk;
  wire tx_sync;
  wire [127:0]tx_tdata;
  wire tx_tready;
  wire [3:0]txn_out;
  wire txout_clk;
  wire [3:0]txp_out;
  wire up_rack;
  wire [15:0]up_raddr;
  wire [31:0]up_rdata;
  wire up_rreq;
  wire up_wack;
  wire [15:0]up_waddr;
  wire [31:0]up_wdata;
  wire up_wreq;

  system system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .GPIO_I(GPIO_I),
        .GPIO_O(GPIO_O),
        .GPIO_T(GPIO_T),
        .SPI0_MISO_I(SPI0_MISO_I),
        .SPI0_MOSI_O(SPI0_MOSI_O),
        .SPI0_SCLK_O(SPI0_SCLK_O),
        .cpll_refclk(cpll_refclk),
        .dpd_rack(dpd_rack),
        .dpd_raddr(dpd_raddr),
        .dpd_rdata(dpd_rdata),
        .dpd_rreq(dpd_rreq),
        .dpd_wack(dpd_wack),
        .dpd_waddr(dpd_waddr),
        .dpd_wdata(dpd_wdata),
        .dpd_wreq(dpd_wreq),
        .fclk_100m(fclk_100m),
        .fclk_resetn(fclk_resetn),
        .fpga_gc_clk(fpga_gc_clk),
        .jesd204b_reset(jesd204b_reset),
        .orx_sync(orx_sync),
        .orx_tdata(orx_tdata),
        .orx_tvalid(orx_tvalid),
        .qpll_refclk(qpll_refclk),
        .rx_sample_clk(rx_sample_clk),
        .rx_sync(rx_sync),
        .rx_tdata(rx_tdata),
        .rx_tvalid(rx_tvalid),
        .rxn_in(rxn_in),
        .rxp_in(rxp_in),
        .sysref(sysref),
        .tx_sample_clk(tx_sample_clk),
        .tx_sync(tx_sync),
        .tx_tdata(tx_tdata),
        .tx_tready(tx_tready),
        .txn_out(txn_out),
        .txout_clk(txout_clk),
        .txp_out(txp_out),
        .up_rack(up_rack),
        .up_raddr(up_raddr),
        .up_rdata(up_rdata),
        .up_rreq(up_rreq),
        .up_wack(up_wack),
        .up_waddr(up_waddr),
        .up_wdata(up_wdata),
        .up_wreq(up_wreq));
endmodule
