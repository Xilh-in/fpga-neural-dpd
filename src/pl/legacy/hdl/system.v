//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
//Date        : Fri Jan 17 02:12:51 2025
//Host        : LAPTOP-VF8QDR9E running 64-bit major release  (build 9200)
//Command     : generate_target system.bd
//Design      : system
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "system,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=system,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=12,numReposBlks=12,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=2,numPkgbdBlks=0,bdsource=USER,da_axi4_cnt=6,da_board_cnt=1,da_clkrst_cnt=3,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "system.hwdef" *) 
module system
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DDR, AXI_ARBITRATION_SCHEME TDM, BURST_LENGTH 8, CAN_DEBUG false, CAS_LATENCY 11, CAS_WRITE_LATENCY 11, CS_ENABLED true, DATA_MASK_ENABLED true, DATA_WIDTH 8, MEMORY_TYPE COMPONENTS, MEM_ADDR_MAP ROW_COLUMN_BANK, SLOT Single, TIMEPERIOD_PS 1250" *) inout [14:0]DDR_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR BA" *) inout [2:0]DDR_ba;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CAS_N" *) inout DDR_cas_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_N" *) inout DDR_ck_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_P" *) inout DDR_ck_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CKE" *) inout DDR_cke;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CS_N" *) inout DDR_cs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DM" *) inout [3:0]DDR_dm;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQ" *) inout [31:0]DDR_dq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_N" *) inout [3:0]DDR_dqs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_P" *) inout [3:0]DDR_dqs_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ODT" *) inout DDR_odt;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RAS_N" *) inout DDR_ras_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RESET_N" *) inout DDR_reset_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR WE_N" *) inout DDR_we_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRN" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIXED_IO, CAN_DEBUG false" *) inout FIXED_IO_ddr_vrn;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRP" *) inout FIXED_IO_ddr_vrp;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO MIO" *) inout [53:0]FIXED_IO_mio;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_CLK" *) inout FIXED_IO_ps_clk;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_PORB" *) inout FIXED_IO_ps_porb;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_SRSTB" *) inout FIXED_IO_ps_srstb;
  input [10:0]GPIO_I;
  output [10:0]GPIO_O;
  output [10:0]GPIO_T;
  input SPI0_MISO_I;
  output SPI0_MOSI_O;
  output SPI0_SCLK_O;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CPLL_REFCLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CPLL_REFCLK, CLK_DOMAIN system_cpll_refclk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input cpll_refclk;
  input dpd_rack;
  output [15:0]dpd_raddr;
  input [31:0]dpd_rdata;
  output dpd_rreq;
  input dpd_wack;
  output [15:0]dpd_waddr;
  output [31:0]dpd_wdata;
  output dpd_wreq;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.FCLK_100M CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.FCLK_100M, CLK_DOMAIN system_processing_system7_0_0_FCLK_CLK0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) output fclk_100m;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.FCLK_RESETN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.FCLK_RESETN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) output fclk_resetn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.FPGA_GC_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.FPGA_GC_CLK, CLK_DOMAIN system_clk_in1_0, FREQ_HZ 122880000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input fpga_gc_clk;
  input jesd204b_reset;
  output orx_sync;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 orx TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME orx, FREQ_HZ 122880000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 0, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [63:0]orx_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 orx TVALID" *) output orx_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.QPLL_REFCLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.QPLL_REFCLK, CLK_DOMAIN system_qpll_refclk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input qpll_refclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.RX_SAMPLE_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.RX_SAMPLE_CLK, CLK_DOMAIN /clk_wiz_0_clk_out1, FREQ_HZ 122880000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) output rx_sample_clk;
  output rx_sync;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rx TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rx, FREQ_HZ 122880000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 0, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [63:0]rx_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rx TVALID" *) output rx_tvalid;
  input [3:0]rxn_in;
  input [3:0]rxp_in;
  input sysref;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.TX_SAMPLE_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.TX_SAMPLE_CLK, CLK_DOMAIN /clk_wiz_0_clk_out1, FREQ_HZ 122880000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) output tx_sample_clk;
  input tx_sync;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 tx TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME tx, FREQ_HZ 61440000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [127:0]tx_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 tx TREADY" *) output tx_tready;
  output [3:0]txn_out;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.TXOUT_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.TXOUT_CLK, CLK_DOMAIN /clk_wiz_0_clk_out1, FREQ_HZ 61440000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) output txout_clk;
  output [3:0]txp_out;
  input up_rack;
  output [15:0]up_raddr;
  input [31:0]up_rdata;
  output up_rreq;
  input up_wack;
  output [15:0]up_waddr;
  output [31:0]up_wdata;
  output up_wreq;

  wire [10:0]GPIO_I_0_1;
  wire SPI0_MISO_I_0_1;
  wire clk_in1_0_1;
  wire clk_wiz_0_clk_out1;
  wire clk_wiz_0_clk_out2;
  wire cpll_refclk_0_1;
  wire [15:0]dpd_axi_up_raddr;
  wire dpd_axi_up_rreq;
  wire [15:0]dpd_axi_up_waddr;
  wire [31:0]dpd_axi_up_wdata;
  wire dpd_axi_up_wreq;
  wire [63:0]jesd204_orx_m_axis_rx_TDATA;
  wire jesd204_orx_m_axis_rx_TVALID;
  wire jesd204_orx_rx_reset_gt;
  wire jesd204_orx_rx_sync;
  wire jesd204_orx_rxencommaalign_out;
  wire [3:0]jesd204_phy_0_gt0_rx_rxcharisk;
  wire [31:0]jesd204_phy_0_gt0_rx_rxdata;
  wire [3:0]jesd204_phy_0_gt0_rx_rxdisperr;
  wire [3:0]jesd204_phy_0_gt0_rx_rxnotintable;
  wire [3:0]jesd204_phy_0_gt1_rx_rxcharisk;
  wire [31:0]jesd204_phy_0_gt1_rx_rxdata;
  wire [3:0]jesd204_phy_0_gt1_rx_rxdisperr;
  wire [3:0]jesd204_phy_0_gt1_rx_rxnotintable;
  wire [3:0]jesd204_phy_0_gt2_rx_rxcharisk;
  wire [31:0]jesd204_phy_0_gt2_rx_rxdata;
  wire [3:0]jesd204_phy_0_gt2_rx_rxdisperr;
  wire [3:0]jesd204_phy_0_gt2_rx_rxnotintable;
  wire [3:0]jesd204_phy_0_gt3_rx_rxcharisk;
  wire [31:0]jesd204_phy_0_gt3_rx_rxdata;
  wire [3:0]jesd204_phy_0_gt3_rx_rxdisperr;
  wire [3:0]jesd204_phy_0_gt3_rx_rxnotintable;
  wire jesd204_phy_0_rx_reset_done;
  wire jesd204_phy_0_tx_reset_done;
  wire [3:0]jesd204_phy_0_txn_out;
  wire [3:0]jesd204_phy_0_txp_out;
  wire [63:0]jesd204_rx_m_axis_rx_TDATA;
  wire jesd204_rx_m_axis_rx_TVALID;
  wire jesd204_rx_rx_reset_gt;
  wire jesd204_rx_rx_sync;
  wire jesd204_rx_rxencommaalign_out;
  wire [3:0]jesd204_tx_gt0_tx_txcharisk;
  wire [31:0]jesd204_tx_gt0_tx_txdata;
  wire [3:0]jesd204_tx_gt1_tx_txcharisk;
  wire [31:0]jesd204_tx_gt1_tx_txdata;
  wire [3:0]jesd204_tx_gt2_tx_txcharisk;
  wire [31:0]jesd204_tx_gt2_tx_txdata;
  wire [3:0]jesd204_tx_gt3_tx_txcharisk;
  wire [31:0]jesd204_tx_gt3_tx_txdata;
  wire [2:0]jesd204_tx_gt_prbssel_out;
  wire jesd204_tx_tx_reset_gt;
  wire [14:0]processing_system7_0_DDR_ADDR;
  wire [2:0]processing_system7_0_DDR_BA;
  wire processing_system7_0_DDR_CAS_N;
  wire processing_system7_0_DDR_CKE;
  wire processing_system7_0_DDR_CK_N;
  wire processing_system7_0_DDR_CK_P;
  wire processing_system7_0_DDR_CS_N;
  wire [3:0]processing_system7_0_DDR_DM;
  wire [31:0]processing_system7_0_DDR_DQ;
  wire [3:0]processing_system7_0_DDR_DQS_N;
  wire [3:0]processing_system7_0_DDR_DQS_P;
  wire processing_system7_0_DDR_ODT;
  wire processing_system7_0_DDR_RAS_N;
  wire processing_system7_0_DDR_RESET_N;
  wire processing_system7_0_DDR_WE_N;
  wire processing_system7_0_FCLK_CLK0;
  wire processing_system7_0_FCLK_RESET0_N;
  wire processing_system7_0_FIXED_IO_DDR_VRN;
  wire processing_system7_0_FIXED_IO_DDR_VRP;
  wire [53:0]processing_system7_0_FIXED_IO_MIO;
  wire processing_system7_0_FIXED_IO_PS_CLK;
  wire processing_system7_0_FIXED_IO_PS_PORB;
  wire processing_system7_0_FIXED_IO_PS_SRSTB;
  wire [10:0]processing_system7_0_GPIO_O;
  wire [10:0]processing_system7_0_GPIO_T;
  wire [31:0]processing_system7_0_M_AXI_GP0_ARADDR;
  wire [1:0]processing_system7_0_M_AXI_GP0_ARBURST;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARCACHE;
  wire [11:0]processing_system7_0_M_AXI_GP0_ARID;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARLEN;
  wire [1:0]processing_system7_0_M_AXI_GP0_ARLOCK;
  wire [2:0]processing_system7_0_M_AXI_GP0_ARPROT;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARQOS;
  wire processing_system7_0_M_AXI_GP0_ARREADY;
  wire [2:0]processing_system7_0_M_AXI_GP0_ARSIZE;
  wire processing_system7_0_M_AXI_GP0_ARVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_AWADDR;
  wire [1:0]processing_system7_0_M_AXI_GP0_AWBURST;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWCACHE;
  wire [11:0]processing_system7_0_M_AXI_GP0_AWID;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWLEN;
  wire [1:0]processing_system7_0_M_AXI_GP0_AWLOCK;
  wire [2:0]processing_system7_0_M_AXI_GP0_AWPROT;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWQOS;
  wire processing_system7_0_M_AXI_GP0_AWREADY;
  wire [2:0]processing_system7_0_M_AXI_GP0_AWSIZE;
  wire processing_system7_0_M_AXI_GP0_AWVALID;
  wire [11:0]processing_system7_0_M_AXI_GP0_BID;
  wire processing_system7_0_M_AXI_GP0_BREADY;
  wire [1:0]processing_system7_0_M_AXI_GP0_BRESP;
  wire processing_system7_0_M_AXI_GP0_BVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_RDATA;
  wire [11:0]processing_system7_0_M_AXI_GP0_RID;
  wire processing_system7_0_M_AXI_GP0_RLAST;
  wire processing_system7_0_M_AXI_GP0_RREADY;
  wire [1:0]processing_system7_0_M_AXI_GP0_RRESP;
  wire processing_system7_0_M_AXI_GP0_RVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_WDATA;
  wire [11:0]processing_system7_0_M_AXI_GP0_WID;
  wire processing_system7_0_M_AXI_GP0_WLAST;
  wire processing_system7_0_M_AXI_GP0_WREADY;
  wire [3:0]processing_system7_0_M_AXI_GP0_WSTRB;
  wire processing_system7_0_M_AXI_GP0_WVALID;
  wire processing_system7_0_SPI0_MOSI_O;
  wire processing_system7_0_SPI0_SCLK_O;
  wire qpll_refclk_0_1;
  wire [0:0]rst_ps7_0_100M_peripheral_aresetn;
  wire [3:0]rxn_in_0_1;
  wire [3:0]rxp_in_0_1;
  wire [127:0]s_axis_tx_0_1_TDATA;
  wire s_axis_tx_0_1_TREADY;
  wire [11:0]smartconnect_0_M00_AXI_ARADDR;
  wire smartconnect_0_M00_AXI_ARREADY;
  wire smartconnect_0_M00_AXI_ARVALID;
  wire [11:0]smartconnect_0_M00_AXI_AWADDR;
  wire smartconnect_0_M00_AXI_AWREADY;
  wire smartconnect_0_M00_AXI_AWVALID;
  wire smartconnect_0_M00_AXI_BREADY;
  wire [1:0]smartconnect_0_M00_AXI_BRESP;
  wire smartconnect_0_M00_AXI_BVALID;
  wire [31:0]smartconnect_0_M00_AXI_RDATA;
  wire smartconnect_0_M00_AXI_RREADY;
  wire [1:0]smartconnect_0_M00_AXI_RRESP;
  wire smartconnect_0_M00_AXI_RVALID;
  wire [31:0]smartconnect_0_M00_AXI_WDATA;
  wire smartconnect_0_M00_AXI_WREADY;
  wire [3:0]smartconnect_0_M00_AXI_WSTRB;
  wire smartconnect_0_M00_AXI_WVALID;
  wire [11:0]smartconnect_0_M01_AXI_ARADDR;
  wire smartconnect_0_M01_AXI_ARREADY;
  wire smartconnect_0_M01_AXI_ARVALID;
  wire [11:0]smartconnect_0_M01_AXI_AWADDR;
  wire smartconnect_0_M01_AXI_AWREADY;
  wire smartconnect_0_M01_AXI_AWVALID;
  wire smartconnect_0_M01_AXI_BREADY;
  wire [1:0]smartconnect_0_M01_AXI_BRESP;
  wire smartconnect_0_M01_AXI_BVALID;
  wire [31:0]smartconnect_0_M01_AXI_RDATA;
  wire smartconnect_0_M01_AXI_RREADY;
  wire [1:0]smartconnect_0_M01_AXI_RRESP;
  wire smartconnect_0_M01_AXI_RVALID;
  wire [31:0]smartconnect_0_M01_AXI_WDATA;
  wire smartconnect_0_M01_AXI_WREADY;
  wire smartconnect_0_M01_AXI_WVALID;
  wire [11:0]smartconnect_0_M02_AXI_ARADDR;
  wire smartconnect_0_M02_AXI_ARREADY;
  wire smartconnect_0_M02_AXI_ARVALID;
  wire [11:0]smartconnect_0_M02_AXI_AWADDR;
  wire smartconnect_0_M02_AXI_AWREADY;
  wire smartconnect_0_M02_AXI_AWVALID;
  wire smartconnect_0_M02_AXI_BREADY;
  wire [1:0]smartconnect_0_M02_AXI_BRESP;
  wire smartconnect_0_M02_AXI_BVALID;
  wire [31:0]smartconnect_0_M02_AXI_RDATA;
  wire smartconnect_0_M02_AXI_RREADY;
  wire [1:0]smartconnect_0_M02_AXI_RRESP;
  wire smartconnect_0_M02_AXI_RVALID;
  wire [31:0]smartconnect_0_M02_AXI_WDATA;
  wire smartconnect_0_M02_AXI_WREADY;
  wire [3:0]smartconnect_0_M02_AXI_WSTRB;
  wire smartconnect_0_M02_AXI_WVALID;
  wire [11:0]smartconnect_0_M03_AXI_ARADDR;
  wire smartconnect_0_M03_AXI_ARREADY;
  wire smartconnect_0_M03_AXI_ARVALID;
  wire [11:0]smartconnect_0_M03_AXI_AWADDR;
  wire smartconnect_0_M03_AXI_AWREADY;
  wire smartconnect_0_M03_AXI_AWVALID;
  wire smartconnect_0_M03_AXI_BREADY;
  wire [1:0]smartconnect_0_M03_AXI_BRESP;
  wire smartconnect_0_M03_AXI_BVALID;
  wire [31:0]smartconnect_0_M03_AXI_RDATA;
  wire smartconnect_0_M03_AXI_RREADY;
  wire [1:0]smartconnect_0_M03_AXI_RRESP;
  wire smartconnect_0_M03_AXI_RVALID;
  wire [31:0]smartconnect_0_M03_AXI_WDATA;
  wire smartconnect_0_M03_AXI_WREADY;
  wire [3:0]smartconnect_0_M03_AXI_WSTRB;
  wire smartconnect_0_M03_AXI_WVALID;
  wire [15:0]smartconnect_0_M04_AXI_ARADDR;
  wire smartconnect_0_M04_AXI_ARREADY;
  wire smartconnect_0_M04_AXI_ARVALID;
  wire [15:0]smartconnect_0_M04_AXI_AWADDR;
  wire smartconnect_0_M04_AXI_AWREADY;
  wire smartconnect_0_M04_AXI_AWVALID;
  wire smartconnect_0_M04_AXI_BREADY;
  wire [1:0]smartconnect_0_M04_AXI_BRESP;
  wire smartconnect_0_M04_AXI_BVALID;
  wire [31:0]smartconnect_0_M04_AXI_RDATA;
  wire smartconnect_0_M04_AXI_RREADY;
  wire [1:0]smartconnect_0_M04_AXI_RRESP;
  wire smartconnect_0_M04_AXI_RVALID;
  wire [31:0]smartconnect_0_M04_AXI_WDATA;
  wire smartconnect_0_M04_AXI_WREADY;
  wire [3:0]smartconnect_0_M04_AXI_WSTRB;
  wire smartconnect_0_M04_AXI_WVALID;
  wire [15:0]smartconnect_0_M05_AXI_ARADDR;
  wire smartconnect_0_M05_AXI_ARREADY;
  wire smartconnect_0_M05_AXI_ARVALID;
  wire [15:0]smartconnect_0_M05_AXI_AWADDR;
  wire smartconnect_0_M05_AXI_AWREADY;
  wire smartconnect_0_M05_AXI_AWVALID;
  wire smartconnect_0_M05_AXI_BREADY;
  wire [1:0]smartconnect_0_M05_AXI_BRESP;
  wire smartconnect_0_M05_AXI_BVALID;
  wire [31:0]smartconnect_0_M05_AXI_RDATA;
  wire smartconnect_0_M05_AXI_RREADY;
  wire [1:0]smartconnect_0_M05_AXI_RRESP;
  wire smartconnect_0_M05_AXI_RVALID;
  wire [31:0]smartconnect_0_M05_AXI_WDATA;
  wire smartconnect_0_M05_AXI_WREADY;
  wire [3:0]smartconnect_0_M05_AXI_WSTRB;
  wire smartconnect_0_M05_AXI_WVALID;
  wire tx_reset_0_1;
  wire tx_sync_0_1;
  wire tx_sysref_0_1;
  wire [15:0]up_axi_0_up_raddr;
  wire up_axi_0_up_rreq;
  wire [15:0]up_axi_0_up_waddr;
  wire [31:0]up_axi_0_up_wdata;
  wire up_axi_0_up_wreq;
  wire up_rack_0_1;
  wire up_rack_0_2;
  wire [31:0]up_rdata_0_1;
  wire [31:0]up_rdata_0_2;
  wire up_wack_0_1;
  wire up_wack_0_2;
  wire [7:0]util_vector_logic_0_Res;
  wire [7:0]util_vector_logic_1_Res;

  assign GPIO_I_0_1 = GPIO_I[10:0];
  assign GPIO_O[10:0] = processing_system7_0_GPIO_O;
  assign GPIO_T[10:0] = processing_system7_0_GPIO_T;
  assign SPI0_MISO_I_0_1 = SPI0_MISO_I;
  assign SPI0_MOSI_O = processing_system7_0_SPI0_MOSI_O;
  assign SPI0_SCLK_O = processing_system7_0_SPI0_SCLK_O;
  assign clk_in1_0_1 = fpga_gc_clk;
  assign cpll_refclk_0_1 = cpll_refclk;
  assign dpd_raddr[15:0] = dpd_axi_up_raddr;
  assign dpd_rreq = dpd_axi_up_rreq;
  assign dpd_waddr[15:0] = dpd_axi_up_waddr;
  assign dpd_wdata[31:0] = dpd_axi_up_wdata;
  assign dpd_wreq = dpd_axi_up_wreq;
  assign fclk_100m = processing_system7_0_FCLK_CLK0;
  assign fclk_resetn = processing_system7_0_FCLK_RESET0_N;
  assign orx_sync = jesd204_orx_rx_sync;
  assign orx_tdata[63:0] = jesd204_orx_m_axis_rx_TDATA;
  assign orx_tvalid = jesd204_orx_m_axis_rx_TVALID;
  assign qpll_refclk_0_1 = qpll_refclk;
  assign rx_sample_clk = clk_wiz_0_clk_out2;
  assign rx_sync = jesd204_rx_rx_sync;
  assign rx_tdata[63:0] = jesd204_rx_m_axis_rx_TDATA;
  assign rx_tvalid = jesd204_rx_m_axis_rx_TVALID;
  assign rxn_in_0_1 = rxn_in[3:0];
  assign rxp_in_0_1 = rxp_in[3:0];
  assign s_axis_tx_0_1_TDATA = tx_tdata[127:0];
  assign tx_reset_0_1 = jesd204b_reset;
  assign tx_sample_clk = clk_wiz_0_clk_out2;
  assign tx_sync_0_1 = tx_sync;
  assign tx_sysref_0_1 = sysref;
  assign tx_tready = s_axis_tx_0_1_TREADY;
  assign txn_out[3:0] = jesd204_phy_0_txn_out;
  assign txout_clk = clk_wiz_0_clk_out1;
  assign txp_out[3:0] = jesd204_phy_0_txp_out;
  assign up_rack_0_1 = up_rack;
  assign up_rack_0_2 = dpd_rack;
  assign up_raddr[15:0] = up_axi_0_up_raddr;
  assign up_rdata_0_1 = up_rdata[31:0];
  assign up_rdata_0_2 = dpd_rdata[31:0];
  assign up_rreq = up_axi_0_up_rreq;
  assign up_wack_0_1 = up_wack;
  assign up_wack_0_2 = dpd_wack;
  assign up_waddr[15:0] = up_axi_0_up_waddr;
  assign up_wdata[31:0] = up_axi_0_up_wdata;
  assign up_wreq = up_axi_0_up_wreq;
  system_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(clk_in1_0_1),
        .clk_out1(clk_wiz_0_clk_out1),
        .clk_out2(clk_wiz_0_clk_out2));
  system_up_axi_1_0 dpd_axi
       (.up_axi_araddr(smartconnect_0_M05_AXI_ARADDR),
        .up_axi_arready(smartconnect_0_M05_AXI_ARREADY),
        .up_axi_arvalid(smartconnect_0_M05_AXI_ARVALID),
        .up_axi_awaddr(smartconnect_0_M05_AXI_AWADDR),
        .up_axi_awready(smartconnect_0_M05_AXI_AWREADY),
        .up_axi_awvalid(smartconnect_0_M05_AXI_AWVALID),
        .up_axi_bready(smartconnect_0_M05_AXI_BREADY),
        .up_axi_bresp(smartconnect_0_M05_AXI_BRESP),
        .up_axi_bvalid(smartconnect_0_M05_AXI_BVALID),
        .up_axi_rdata(smartconnect_0_M05_AXI_RDATA),
        .up_axi_rready(smartconnect_0_M05_AXI_RREADY),
        .up_axi_rresp(smartconnect_0_M05_AXI_RRESP),
        .up_axi_rvalid(smartconnect_0_M05_AXI_RVALID),
        .up_axi_wdata(smartconnect_0_M05_AXI_WDATA),
        .up_axi_wready(smartconnect_0_M05_AXI_WREADY),
        .up_axi_wstrb(smartconnect_0_M05_AXI_WSTRB),
        .up_axi_wvalid(smartconnect_0_M05_AXI_WVALID),
        .up_clk(processing_system7_0_FCLK_CLK0),
        .up_rack(up_rack_0_2),
        .up_raddr(dpd_axi_up_raddr),
        .up_rdata(up_rdata_0_2),
        .up_rreq(dpd_axi_up_rreq),
        .up_rstn(rst_ps7_0_100M_peripheral_aresetn),
        .up_wack(up_wack_0_2),
        .up_waddr(dpd_axi_up_waddr),
        .up_wdata(dpd_axi_up_wdata),
        .up_wreq(dpd_axi_up_wreq));
  system_jesd204_0_2 jesd204_orx
       (.gt0_rxcharisk(jesd204_phy_0_gt2_rx_rxcharisk),
        .gt0_rxdata(jesd204_phy_0_gt2_rx_rxdata),
        .gt0_rxdisperr(jesd204_phy_0_gt2_rx_rxdisperr),
        .gt0_rxnotintable(jesd204_phy_0_gt2_rx_rxnotintable),
        .gt1_rxcharisk(jesd204_phy_0_gt3_rx_rxcharisk),
        .gt1_rxdata(jesd204_phy_0_gt3_rx_rxdata),
        .gt1_rxdisperr(jesd204_phy_0_gt3_rx_rxdisperr),
        .gt1_rxnotintable(jesd204_phy_0_gt3_rx_rxnotintable),
        .rx_core_clk(clk_wiz_0_clk_out2),
        .rx_reset(tx_reset_0_1),
        .rx_reset_done(jesd204_phy_0_rx_reset_done),
        .rx_reset_gt(jesd204_orx_rx_reset_gt),
        .rx_sync(jesd204_orx_rx_sync),
        .rx_sysref(tx_sysref_0_1),
        .rx_tdata(jesd204_orx_m_axis_rx_TDATA),
        .rx_tvalid(jesd204_orx_m_axis_rx_TVALID),
        .rxencommaalign_out(jesd204_orx_rxencommaalign_out),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(smartconnect_0_M03_AXI_ARADDR),
        .s_axi_aresetn(rst_ps7_0_100M_peripheral_aresetn),
        .s_axi_arready(smartconnect_0_M03_AXI_ARREADY),
        .s_axi_arvalid(smartconnect_0_M03_AXI_ARVALID),
        .s_axi_awaddr(smartconnect_0_M03_AXI_AWADDR),
        .s_axi_awready(smartconnect_0_M03_AXI_AWREADY),
        .s_axi_awvalid(smartconnect_0_M03_AXI_AWVALID),
        .s_axi_bready(smartconnect_0_M03_AXI_BREADY),
        .s_axi_bresp(smartconnect_0_M03_AXI_BRESP),
        .s_axi_bvalid(smartconnect_0_M03_AXI_BVALID),
        .s_axi_rdata(smartconnect_0_M03_AXI_RDATA),
        .s_axi_rready(smartconnect_0_M03_AXI_RREADY),
        .s_axi_rresp(smartconnect_0_M03_AXI_RRESP),
        .s_axi_rvalid(smartconnect_0_M03_AXI_RVALID),
        .s_axi_wdata(smartconnect_0_M03_AXI_WDATA),
        .s_axi_wready(smartconnect_0_M03_AXI_WREADY),
        .s_axi_wstrb(smartconnect_0_M03_AXI_WSTRB),
        .s_axi_wvalid(smartconnect_0_M03_AXI_WVALID));
  system_jesd204_phy_0_0 jesd204_phy_0
       (.cpll_refclk(cpll_refclk_0_1),
        .drpclk(processing_system7_0_FCLK_CLK0),
        .gt0_rxcharisk(jesd204_phy_0_gt0_rx_rxcharisk),
        .gt0_rxdata(jesd204_phy_0_gt0_rx_rxdata),
        .gt0_rxdisperr(jesd204_phy_0_gt0_rx_rxdisperr),
        .gt0_rxnotintable(jesd204_phy_0_gt0_rx_rxnotintable),
        .gt0_txcharisk(jesd204_tx_gt0_tx_txcharisk),
        .gt0_txdata(jesd204_tx_gt0_tx_txdata),
        .gt1_rxcharisk(jesd204_phy_0_gt1_rx_rxcharisk),
        .gt1_rxdata(jesd204_phy_0_gt1_rx_rxdata),
        .gt1_rxdisperr(jesd204_phy_0_gt1_rx_rxdisperr),
        .gt1_rxnotintable(jesd204_phy_0_gt1_rx_rxnotintable),
        .gt1_txcharisk(jesd204_tx_gt1_tx_txcharisk),
        .gt1_txdata(jesd204_tx_gt1_tx_txdata),
        .gt2_rxcharisk(jesd204_phy_0_gt2_rx_rxcharisk),
        .gt2_rxdata(jesd204_phy_0_gt2_rx_rxdata),
        .gt2_rxdisperr(jesd204_phy_0_gt2_rx_rxdisperr),
        .gt2_rxnotintable(jesd204_phy_0_gt2_rx_rxnotintable),
        .gt2_txcharisk(jesd204_tx_gt2_tx_txcharisk),
        .gt2_txdata(jesd204_tx_gt2_tx_txdata),
        .gt3_rxcharisk(jesd204_phy_0_gt3_rx_rxcharisk),
        .gt3_rxdata(jesd204_phy_0_gt3_rx_rxdata),
        .gt3_rxdisperr(jesd204_phy_0_gt3_rx_rxdisperr),
        .gt3_rxnotintable(jesd204_phy_0_gt3_rx_rxnotintable),
        .gt3_txcharisk(jesd204_tx_gt3_tx_txcharisk),
        .gt3_txdata(jesd204_tx_gt3_tx_txdata),
        .gt_prbssel(jesd204_tx_gt_prbssel_out),
        .qpll_refclk(qpll_refclk_0_1),
        .rx_core_clk(clk_wiz_0_clk_out2),
        .rx_reset_done(jesd204_phy_0_rx_reset_done),
        .rx_reset_gt(util_vector_logic_1_Res[0]),
        .rx_sys_reset(tx_reset_0_1),
        .rxencommaalign(util_vector_logic_0_Res[0]),
        .rxn_in(rxn_in_0_1),
        .rxp_in(rxp_in_0_1),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(smartconnect_0_M01_AXI_ARADDR),
        .s_axi_aresetn(rst_ps7_0_100M_peripheral_aresetn),
        .s_axi_arready(smartconnect_0_M01_AXI_ARREADY),
        .s_axi_arvalid(smartconnect_0_M01_AXI_ARVALID),
        .s_axi_awaddr(smartconnect_0_M01_AXI_AWADDR),
        .s_axi_awready(smartconnect_0_M01_AXI_AWREADY),
        .s_axi_awvalid(smartconnect_0_M01_AXI_AWVALID),
        .s_axi_bready(smartconnect_0_M01_AXI_BREADY),
        .s_axi_bresp(smartconnect_0_M01_AXI_BRESP),
        .s_axi_bvalid(smartconnect_0_M01_AXI_BVALID),
        .s_axi_rdata(smartconnect_0_M01_AXI_RDATA),
        .s_axi_rready(smartconnect_0_M01_AXI_RREADY),
        .s_axi_rresp(smartconnect_0_M01_AXI_RRESP),
        .s_axi_rvalid(smartconnect_0_M01_AXI_RVALID),
        .s_axi_wdata(smartconnect_0_M01_AXI_WDATA),
        .s_axi_wready(smartconnect_0_M01_AXI_WREADY),
        .s_axi_wvalid(smartconnect_0_M01_AXI_WVALID),
        .tx_core_clk(clk_wiz_0_clk_out1),
        .tx_reset_done(jesd204_phy_0_tx_reset_done),
        .tx_reset_gt(jesd204_tx_tx_reset_gt),
        .tx_sys_reset(tx_reset_0_1),
        .txn_out(jesd204_phy_0_txn_out),
        .txp_out(jesd204_phy_0_txp_out));
  system_jesd204_0_1 jesd204_rx
       (.gt0_rxcharisk(jesd204_phy_0_gt0_rx_rxcharisk),
        .gt0_rxdata(jesd204_phy_0_gt0_rx_rxdata),
        .gt0_rxdisperr(jesd204_phy_0_gt0_rx_rxdisperr),
        .gt0_rxnotintable(jesd204_phy_0_gt0_rx_rxnotintable),
        .gt1_rxcharisk(jesd204_phy_0_gt1_rx_rxcharisk),
        .gt1_rxdata(jesd204_phy_0_gt1_rx_rxdata),
        .gt1_rxdisperr(jesd204_phy_0_gt1_rx_rxdisperr),
        .gt1_rxnotintable(jesd204_phy_0_gt1_rx_rxnotintable),
        .rx_core_clk(clk_wiz_0_clk_out2),
        .rx_reset(tx_reset_0_1),
        .rx_reset_done(jesd204_phy_0_rx_reset_done),
        .rx_reset_gt(jesd204_rx_rx_reset_gt),
        .rx_sync(jesd204_rx_rx_sync),
        .rx_sysref(tx_sysref_0_1),
        .rx_tdata(jesd204_rx_m_axis_rx_TDATA),
        .rx_tvalid(jesd204_rx_m_axis_rx_TVALID),
        .rxencommaalign_out(jesd204_rx_rxencommaalign_out),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(smartconnect_0_M02_AXI_ARADDR),
        .s_axi_aresetn(rst_ps7_0_100M_peripheral_aresetn),
        .s_axi_arready(smartconnect_0_M02_AXI_ARREADY),
        .s_axi_arvalid(smartconnect_0_M02_AXI_ARVALID),
        .s_axi_awaddr(smartconnect_0_M02_AXI_AWADDR),
        .s_axi_awready(smartconnect_0_M02_AXI_AWREADY),
        .s_axi_awvalid(smartconnect_0_M02_AXI_AWVALID),
        .s_axi_bready(smartconnect_0_M02_AXI_BREADY),
        .s_axi_bresp(smartconnect_0_M02_AXI_BRESP),
        .s_axi_bvalid(smartconnect_0_M02_AXI_BVALID),
        .s_axi_rdata(smartconnect_0_M02_AXI_RDATA),
        .s_axi_rready(smartconnect_0_M02_AXI_RREADY),
        .s_axi_rresp(smartconnect_0_M02_AXI_RRESP),
        .s_axi_rvalid(smartconnect_0_M02_AXI_RVALID),
        .s_axi_wdata(smartconnect_0_M02_AXI_WDATA),
        .s_axi_wready(smartconnect_0_M02_AXI_WREADY),
        .s_axi_wstrb(smartconnect_0_M02_AXI_WSTRB),
        .s_axi_wvalid(smartconnect_0_M02_AXI_WVALID));
  system_jesd204_0_0 jesd204_tx
       (.gt0_txcharisk(jesd204_tx_gt0_tx_txcharisk),
        .gt0_txdata(jesd204_tx_gt0_tx_txdata),
        .gt1_txcharisk(jesd204_tx_gt1_tx_txcharisk),
        .gt1_txdata(jesd204_tx_gt1_tx_txdata),
        .gt2_txcharisk(jesd204_tx_gt2_tx_txcharisk),
        .gt2_txdata(jesd204_tx_gt2_tx_txdata),
        .gt3_txcharisk(jesd204_tx_gt3_tx_txcharisk),
        .gt3_txdata(jesd204_tx_gt3_tx_txdata),
        .gt_prbssel_out(jesd204_tx_gt_prbssel_out),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(smartconnect_0_M00_AXI_ARADDR),
        .s_axi_aresetn(rst_ps7_0_100M_peripheral_aresetn),
        .s_axi_arready(smartconnect_0_M00_AXI_ARREADY),
        .s_axi_arvalid(smartconnect_0_M00_AXI_ARVALID),
        .s_axi_awaddr(smartconnect_0_M00_AXI_AWADDR),
        .s_axi_awready(smartconnect_0_M00_AXI_AWREADY),
        .s_axi_awvalid(smartconnect_0_M00_AXI_AWVALID),
        .s_axi_bready(smartconnect_0_M00_AXI_BREADY),
        .s_axi_bresp(smartconnect_0_M00_AXI_BRESP),
        .s_axi_bvalid(smartconnect_0_M00_AXI_BVALID),
        .s_axi_rdata(smartconnect_0_M00_AXI_RDATA),
        .s_axi_rready(smartconnect_0_M00_AXI_RREADY),
        .s_axi_rresp(smartconnect_0_M00_AXI_RRESP),
        .s_axi_rvalid(smartconnect_0_M00_AXI_RVALID),
        .s_axi_wdata(smartconnect_0_M00_AXI_WDATA),
        .s_axi_wready(smartconnect_0_M00_AXI_WREADY),
        .s_axi_wstrb(smartconnect_0_M00_AXI_WSTRB),
        .s_axi_wvalid(smartconnect_0_M00_AXI_WVALID),
        .tx_core_clk(clk_wiz_0_clk_out1),
        .tx_reset(tx_reset_0_1),
        .tx_reset_done(jesd204_phy_0_tx_reset_done),
        .tx_reset_gt(jesd204_tx_tx_reset_gt),
        .tx_sync(tx_sync_0_1),
        .tx_sysref(tx_sysref_0_1),
        .tx_tdata(s_axis_tx_0_1_TDATA),
        .tx_tready(s_axis_tx_0_1_TREADY));
  system_processing_system7_0_0 processing_system7_0
       (.DDR_Addr(DDR_addr[14:0]),
        .DDR_BankAddr(DDR_ba[2:0]),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm[3:0]),
        .DDR_DQ(DDR_dq[31:0]),
        .DDR_DQS(DDR_dqs_p[3:0]),
        .DDR_DQS_n(DDR_dqs_n[3:0]),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),
        .FCLK_CLK0(processing_system7_0_FCLK_CLK0),
        .FCLK_RESET0_N(processing_system7_0_FCLK_RESET0_N),
        .GPIO_I(GPIO_I_0_1),
        .GPIO_O(processing_system7_0_GPIO_O),
        .GPIO_T(processing_system7_0_GPIO_T),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(processing_system7_0_FCLK_CLK0),
        .M_AXI_GP0_ARADDR(processing_system7_0_M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARBURST(processing_system7_0_M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARCACHE(processing_system7_0_M_AXI_GP0_ARCACHE),
        .M_AXI_GP0_ARID(processing_system7_0_M_AXI_GP0_ARID),
        .M_AXI_GP0_ARLEN(processing_system7_0_M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARLOCK(processing_system7_0_M_AXI_GP0_ARLOCK),
        .M_AXI_GP0_ARPROT(processing_system7_0_M_AXI_GP0_ARPROT),
        .M_AXI_GP0_ARQOS(processing_system7_0_M_AXI_GP0_ARQOS),
        .M_AXI_GP0_ARREADY(processing_system7_0_M_AXI_GP0_ARREADY),
        .M_AXI_GP0_ARSIZE(processing_system7_0_M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARVALID(processing_system7_0_M_AXI_GP0_ARVALID),
        .M_AXI_GP0_AWADDR(processing_system7_0_M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWBURST(processing_system7_0_M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWCACHE(processing_system7_0_M_AXI_GP0_AWCACHE),
        .M_AXI_GP0_AWID(processing_system7_0_M_AXI_GP0_AWID),
        .M_AXI_GP0_AWLEN(processing_system7_0_M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWLOCK(processing_system7_0_M_AXI_GP0_AWLOCK),
        .M_AXI_GP0_AWPROT(processing_system7_0_M_AXI_GP0_AWPROT),
        .M_AXI_GP0_AWQOS(processing_system7_0_M_AXI_GP0_AWQOS),
        .M_AXI_GP0_AWREADY(processing_system7_0_M_AXI_GP0_AWREADY),
        .M_AXI_GP0_AWSIZE(processing_system7_0_M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWVALID(processing_system7_0_M_AXI_GP0_AWVALID),
        .M_AXI_GP0_BID(processing_system7_0_M_AXI_GP0_BID),
        .M_AXI_GP0_BREADY(processing_system7_0_M_AXI_GP0_BREADY),
        .M_AXI_GP0_BRESP(processing_system7_0_M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(processing_system7_0_M_AXI_GP0_BVALID),
        .M_AXI_GP0_RDATA(processing_system7_0_M_AXI_GP0_RDATA),
        .M_AXI_GP0_RID(processing_system7_0_M_AXI_GP0_RID),
        .M_AXI_GP0_RLAST(processing_system7_0_M_AXI_GP0_RLAST),
        .M_AXI_GP0_RREADY(processing_system7_0_M_AXI_GP0_RREADY),
        .M_AXI_GP0_RRESP(processing_system7_0_M_AXI_GP0_RRESP),
        .M_AXI_GP0_RVALID(processing_system7_0_M_AXI_GP0_RVALID),
        .M_AXI_GP0_WDATA(processing_system7_0_M_AXI_GP0_WDATA),
        .M_AXI_GP0_WID(processing_system7_0_M_AXI_GP0_WID),
        .M_AXI_GP0_WLAST(processing_system7_0_M_AXI_GP0_WLAST),
        .M_AXI_GP0_WREADY(processing_system7_0_M_AXI_GP0_WREADY),
        .M_AXI_GP0_WSTRB(processing_system7_0_M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WVALID(processing_system7_0_M_AXI_GP0_WVALID),
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
        .SPI0_MISO_I(SPI0_MISO_I_0_1),
        .SPI0_MOSI_I(1'b0),
        .SPI0_MOSI_O(processing_system7_0_SPI0_MOSI_O),
        .SPI0_SCLK_I(1'b0),
        .SPI0_SCLK_O(processing_system7_0_SPI0_SCLK_O),
        .SPI0_SS_I(1'b0));
  system_proc_sys_reset_0_0 rst_ps7_0_100M
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_ps7_0_100M_peripheral_aresetn),
        .slowest_sync_clk(processing_system7_0_FCLK_CLK0));
  system_smartconnect_0_0 smartconnect_0
       (.M00_AXI_araddr(smartconnect_0_M00_AXI_ARADDR),
        .M00_AXI_arready(smartconnect_0_M00_AXI_ARREADY),
        .M00_AXI_arvalid(smartconnect_0_M00_AXI_ARVALID),
        .M00_AXI_awaddr(smartconnect_0_M00_AXI_AWADDR),
        .M00_AXI_awready(smartconnect_0_M00_AXI_AWREADY),
        .M00_AXI_awvalid(smartconnect_0_M00_AXI_AWVALID),
        .M00_AXI_bready(smartconnect_0_M00_AXI_BREADY),
        .M00_AXI_bresp(smartconnect_0_M00_AXI_BRESP),
        .M00_AXI_bvalid(smartconnect_0_M00_AXI_BVALID),
        .M00_AXI_rdata(smartconnect_0_M00_AXI_RDATA),
        .M00_AXI_rready(smartconnect_0_M00_AXI_RREADY),
        .M00_AXI_rresp(smartconnect_0_M00_AXI_RRESP),
        .M00_AXI_rvalid(smartconnect_0_M00_AXI_RVALID),
        .M00_AXI_wdata(smartconnect_0_M00_AXI_WDATA),
        .M00_AXI_wready(smartconnect_0_M00_AXI_WREADY),
        .M00_AXI_wstrb(smartconnect_0_M00_AXI_WSTRB),
        .M00_AXI_wvalid(smartconnect_0_M00_AXI_WVALID),
        .M01_AXI_araddr(smartconnect_0_M01_AXI_ARADDR),
        .M01_AXI_arready(smartconnect_0_M01_AXI_ARREADY),
        .M01_AXI_arvalid(smartconnect_0_M01_AXI_ARVALID),
        .M01_AXI_awaddr(smartconnect_0_M01_AXI_AWADDR),
        .M01_AXI_awready(smartconnect_0_M01_AXI_AWREADY),
        .M01_AXI_awvalid(smartconnect_0_M01_AXI_AWVALID),
        .M01_AXI_bready(smartconnect_0_M01_AXI_BREADY),
        .M01_AXI_bresp(smartconnect_0_M01_AXI_BRESP),
        .M01_AXI_bvalid(smartconnect_0_M01_AXI_BVALID),
        .M01_AXI_rdata(smartconnect_0_M01_AXI_RDATA),
        .M01_AXI_rready(smartconnect_0_M01_AXI_RREADY),
        .M01_AXI_rresp(smartconnect_0_M01_AXI_RRESP),
        .M01_AXI_rvalid(smartconnect_0_M01_AXI_RVALID),
        .M01_AXI_wdata(smartconnect_0_M01_AXI_WDATA),
        .M01_AXI_wready(smartconnect_0_M01_AXI_WREADY),
        .M01_AXI_wvalid(smartconnect_0_M01_AXI_WVALID),
        .M02_AXI_araddr(smartconnect_0_M02_AXI_ARADDR),
        .M02_AXI_arready(smartconnect_0_M02_AXI_ARREADY),
        .M02_AXI_arvalid(smartconnect_0_M02_AXI_ARVALID),
        .M02_AXI_awaddr(smartconnect_0_M02_AXI_AWADDR),
        .M02_AXI_awready(smartconnect_0_M02_AXI_AWREADY),
        .M02_AXI_awvalid(smartconnect_0_M02_AXI_AWVALID),
        .M02_AXI_bready(smartconnect_0_M02_AXI_BREADY),
        .M02_AXI_bresp(smartconnect_0_M02_AXI_BRESP),
        .M02_AXI_bvalid(smartconnect_0_M02_AXI_BVALID),
        .M02_AXI_rdata(smartconnect_0_M02_AXI_RDATA),
        .M02_AXI_rready(smartconnect_0_M02_AXI_RREADY),
        .M02_AXI_rresp(smartconnect_0_M02_AXI_RRESP),
        .M02_AXI_rvalid(smartconnect_0_M02_AXI_RVALID),
        .M02_AXI_wdata(smartconnect_0_M02_AXI_WDATA),
        .M02_AXI_wready(smartconnect_0_M02_AXI_WREADY),
        .M02_AXI_wstrb(smartconnect_0_M02_AXI_WSTRB),
        .M02_AXI_wvalid(smartconnect_0_M02_AXI_WVALID),
        .M03_AXI_araddr(smartconnect_0_M03_AXI_ARADDR),
        .M03_AXI_arready(smartconnect_0_M03_AXI_ARREADY),
        .M03_AXI_arvalid(smartconnect_0_M03_AXI_ARVALID),
        .M03_AXI_awaddr(smartconnect_0_M03_AXI_AWADDR),
        .M03_AXI_awready(smartconnect_0_M03_AXI_AWREADY),
        .M03_AXI_awvalid(smartconnect_0_M03_AXI_AWVALID),
        .M03_AXI_bready(smartconnect_0_M03_AXI_BREADY),
        .M03_AXI_bresp(smartconnect_0_M03_AXI_BRESP),
        .M03_AXI_bvalid(smartconnect_0_M03_AXI_BVALID),
        .M03_AXI_rdata(smartconnect_0_M03_AXI_RDATA),
        .M03_AXI_rready(smartconnect_0_M03_AXI_RREADY),
        .M03_AXI_rresp(smartconnect_0_M03_AXI_RRESP),
        .M03_AXI_rvalid(smartconnect_0_M03_AXI_RVALID),
        .M03_AXI_wdata(smartconnect_0_M03_AXI_WDATA),
        .M03_AXI_wready(smartconnect_0_M03_AXI_WREADY),
        .M03_AXI_wstrb(smartconnect_0_M03_AXI_WSTRB),
        .M03_AXI_wvalid(smartconnect_0_M03_AXI_WVALID),
        .M04_AXI_araddr(smartconnect_0_M04_AXI_ARADDR),
        .M04_AXI_arready(smartconnect_0_M04_AXI_ARREADY),
        .M04_AXI_arvalid(smartconnect_0_M04_AXI_ARVALID),
        .M04_AXI_awaddr(smartconnect_0_M04_AXI_AWADDR),
        .M04_AXI_awready(smartconnect_0_M04_AXI_AWREADY),
        .M04_AXI_awvalid(smartconnect_0_M04_AXI_AWVALID),
        .M04_AXI_bready(smartconnect_0_M04_AXI_BREADY),
        .M04_AXI_bresp(smartconnect_0_M04_AXI_BRESP),
        .M04_AXI_bvalid(smartconnect_0_M04_AXI_BVALID),
        .M04_AXI_rdata(smartconnect_0_M04_AXI_RDATA),
        .M04_AXI_rready(smartconnect_0_M04_AXI_RREADY),
        .M04_AXI_rresp(smartconnect_0_M04_AXI_RRESP),
        .M04_AXI_rvalid(smartconnect_0_M04_AXI_RVALID),
        .M04_AXI_wdata(smartconnect_0_M04_AXI_WDATA),
        .M04_AXI_wready(smartconnect_0_M04_AXI_WREADY),
        .M04_AXI_wstrb(smartconnect_0_M04_AXI_WSTRB),
        .M04_AXI_wvalid(smartconnect_0_M04_AXI_WVALID),
        .M05_AXI_araddr(smartconnect_0_M05_AXI_ARADDR),
        .M05_AXI_arready(smartconnect_0_M05_AXI_ARREADY),
        .M05_AXI_arvalid(smartconnect_0_M05_AXI_ARVALID),
        .M05_AXI_awaddr(smartconnect_0_M05_AXI_AWADDR),
        .M05_AXI_awready(smartconnect_0_M05_AXI_AWREADY),
        .M05_AXI_awvalid(smartconnect_0_M05_AXI_AWVALID),
        .M05_AXI_bready(smartconnect_0_M05_AXI_BREADY),
        .M05_AXI_bresp(smartconnect_0_M05_AXI_BRESP),
        .M05_AXI_bvalid(smartconnect_0_M05_AXI_BVALID),
        .M05_AXI_rdata(smartconnect_0_M05_AXI_RDATA),
        .M05_AXI_rready(smartconnect_0_M05_AXI_RREADY),
        .M05_AXI_rresp(smartconnect_0_M05_AXI_RRESP),
        .M05_AXI_rvalid(smartconnect_0_M05_AXI_RVALID),
        .M05_AXI_wdata(smartconnect_0_M05_AXI_WDATA),
        .M05_AXI_wready(smartconnect_0_M05_AXI_WREADY),
        .M05_AXI_wstrb(smartconnect_0_M05_AXI_WSTRB),
        .M05_AXI_wvalid(smartconnect_0_M05_AXI_WVALID),
        .S00_AXI_araddr(processing_system7_0_M_AXI_GP0_ARADDR),
        .S00_AXI_arburst(processing_system7_0_M_AXI_GP0_ARBURST),
        .S00_AXI_arcache(processing_system7_0_M_AXI_GP0_ARCACHE),
        .S00_AXI_arid(processing_system7_0_M_AXI_GP0_ARID),
        .S00_AXI_arlen(processing_system7_0_M_AXI_GP0_ARLEN),
        .S00_AXI_arlock(processing_system7_0_M_AXI_GP0_ARLOCK),
        .S00_AXI_arprot(processing_system7_0_M_AXI_GP0_ARPROT),
        .S00_AXI_arqos(processing_system7_0_M_AXI_GP0_ARQOS),
        .S00_AXI_arready(processing_system7_0_M_AXI_GP0_ARREADY),
        .S00_AXI_arsize(processing_system7_0_M_AXI_GP0_ARSIZE),
        .S00_AXI_arvalid(processing_system7_0_M_AXI_GP0_ARVALID),
        .S00_AXI_awaddr(processing_system7_0_M_AXI_GP0_AWADDR),
        .S00_AXI_awburst(processing_system7_0_M_AXI_GP0_AWBURST),
        .S00_AXI_awcache(processing_system7_0_M_AXI_GP0_AWCACHE),
        .S00_AXI_awid(processing_system7_0_M_AXI_GP0_AWID),
        .S00_AXI_awlen(processing_system7_0_M_AXI_GP0_AWLEN),
        .S00_AXI_awlock(processing_system7_0_M_AXI_GP0_AWLOCK),
        .S00_AXI_awprot(processing_system7_0_M_AXI_GP0_AWPROT),
        .S00_AXI_awqos(processing_system7_0_M_AXI_GP0_AWQOS),
        .S00_AXI_awready(processing_system7_0_M_AXI_GP0_AWREADY),
        .S00_AXI_awsize(processing_system7_0_M_AXI_GP0_AWSIZE),
        .S00_AXI_awvalid(processing_system7_0_M_AXI_GP0_AWVALID),
        .S00_AXI_bid(processing_system7_0_M_AXI_GP0_BID),
        .S00_AXI_bready(processing_system7_0_M_AXI_GP0_BREADY),
        .S00_AXI_bresp(processing_system7_0_M_AXI_GP0_BRESP),
        .S00_AXI_bvalid(processing_system7_0_M_AXI_GP0_BVALID),
        .S00_AXI_rdata(processing_system7_0_M_AXI_GP0_RDATA),
        .S00_AXI_rid(processing_system7_0_M_AXI_GP0_RID),
        .S00_AXI_rlast(processing_system7_0_M_AXI_GP0_RLAST),
        .S00_AXI_rready(processing_system7_0_M_AXI_GP0_RREADY),
        .S00_AXI_rresp(processing_system7_0_M_AXI_GP0_RRESP),
        .S00_AXI_rvalid(processing_system7_0_M_AXI_GP0_RVALID),
        .S00_AXI_wdata(processing_system7_0_M_AXI_GP0_WDATA),
        .S00_AXI_wid(processing_system7_0_M_AXI_GP0_WID),
        .S00_AXI_wlast(processing_system7_0_M_AXI_GP0_WLAST),
        .S00_AXI_wready(processing_system7_0_M_AXI_GP0_WREADY),
        .S00_AXI_wstrb(processing_system7_0_M_AXI_GP0_WSTRB),
        .S00_AXI_wvalid(processing_system7_0_M_AXI_GP0_WVALID),
        .aclk(processing_system7_0_FCLK_CLK0),
        .aresetn(rst_ps7_0_100M_peripheral_aresetn));
  system_up_axi_0_0 up_axi_0
       (.up_axi_araddr(smartconnect_0_M04_AXI_ARADDR),
        .up_axi_arready(smartconnect_0_M04_AXI_ARREADY),
        .up_axi_arvalid(smartconnect_0_M04_AXI_ARVALID),
        .up_axi_awaddr(smartconnect_0_M04_AXI_AWADDR),
        .up_axi_awready(smartconnect_0_M04_AXI_AWREADY),
        .up_axi_awvalid(smartconnect_0_M04_AXI_AWVALID),
        .up_axi_bready(smartconnect_0_M04_AXI_BREADY),
        .up_axi_bresp(smartconnect_0_M04_AXI_BRESP),
        .up_axi_bvalid(smartconnect_0_M04_AXI_BVALID),
        .up_axi_rdata(smartconnect_0_M04_AXI_RDATA),
        .up_axi_rready(smartconnect_0_M04_AXI_RREADY),
        .up_axi_rresp(smartconnect_0_M04_AXI_RRESP),
        .up_axi_rvalid(smartconnect_0_M04_AXI_RVALID),
        .up_axi_wdata(smartconnect_0_M04_AXI_WDATA),
        .up_axi_wready(smartconnect_0_M04_AXI_WREADY),
        .up_axi_wstrb(smartconnect_0_M04_AXI_WSTRB),
        .up_axi_wvalid(smartconnect_0_M04_AXI_WVALID),
        .up_clk(processing_system7_0_FCLK_CLK0),
        .up_rack(up_rack_0_1),
        .up_raddr(up_axi_0_up_raddr),
        .up_rdata(up_rdata_0_1),
        .up_rreq(up_axi_0_up_rreq),
        .up_rstn(rst_ps7_0_100M_peripheral_aresetn),
        .up_wack(up_wack_0_1),
        .up_waddr(up_axi_0_up_waddr),
        .up_wdata(up_axi_0_up_wdata),
        .up_wreq(up_axi_0_up_wreq));
  system_util_vector_logic_0_0 util_vector_logic_0
       (.Op1({jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out,jesd204_orx_rxencommaalign_out}),
        .Op2({jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out,jesd204_rx_rxencommaalign_out}),
        .Res(util_vector_logic_0_Res));
  system_util_vector_logic_1_0 util_vector_logic_1
       (.Op1({jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt,jesd204_orx_rx_reset_gt}),
        .Op2({jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt,jesd204_rx_rx_reset_gt}),
        .Res(util_vector_logic_1_Res));
endmodule
