`timescale 1ns / 1ps
module axi_lite_dpd(
//global
    input                               axi_gp_clk                 ,
    input                               axi_rst_n                  ,
// AXI Lite Master Interface connections
    input                               up_wreq                    ,
    input              [  15: 0]        up_waddr                   ,
    input              [  31: 0]        up_wdata                   ,
    output reg                          up_wack                    ,

    input                               up_rreq                    ,
    input              [  15: 0]        up_raddr                   ,
    output reg         [  31: 0]        up_rdata                   ,
    output reg                          up_rack                    ,
//register tx
    input                               tx_sample_clk              ,
    output             [  15: 0]        tx1_idata                  ,
    output             [  15: 0]        tx1_qdata                  ,
    output             [  15: 0]        tx2_idata                  ,
    output             [  15: 0]        tx2_qdata                  ,
//register rx
    input                               rx_sample_clk              ,
    input              [  15: 0]        rx1_idata                  ,
    input              [  15: 0]        rx1_qdata                  ,
    input              [  15: 0]        rx2_idata                  ,
    input              [  15: 0]        rx2_qdata                   
);
//=======================================================================================
// data_ctrl slave reg                                                                                     
//=======================================================================================
// time delay, amplitude and phase align  
    reg                                 align_en                   ;
    reg                [   9: 0]        delay                      ;
    reg                [  31: 0]        apc_k_i                    ;
    reg                [  31: 0]        apc_k_q                    ;

// cap data
    reg                [   5: 0]        cap_data_cmd               ;
    reg                [  15: 0]        cap_len                    ;
    reg                [  31: 0]        trigger_point              ;
    reg                [  15: 0]        cap_rd_addr                ;
    wire               [  31: 0]        cap_data_rdata             ;

// tx data 
    reg                                 tx_vld                     ;
    reg                                 tx_data_en                 ;
    reg                                 tx_data_wr                 ;
    reg                [  15: 0]        tx_data_addr               ;
    reg                [  31: 0]        tx_data_wdata              ;
    wire               [  31: 0]        tx_data_rdata              ;

// dpd
    reg                [   2: 0]        ch_sel                     ;
    reg                                 dpd_en                     ;
    reg                                 dpd_coe_en                 ;
    reg                                 dpd_coe_wr                 ;
    reg                [   9: 0]        dpd_coe_addr               ;
    reg                [  15: 0]        dpd_coe_wdata              ;
    wire               [  15: 0]        dpd_coe_rdata              ;
    wire               [  31: 0]        dpd_out                    ;

// cyclic
    reg                                 cyclic_en                  ;
    reg                                 cyclic_data_en             ;
    reg                                 cyclic_data_wr             ;
    reg                [  15: 0]        cyclic_data_addr           ;
    reg                [  31: 0]        cyclic_data_wdata          ;
    wire               [  31: 0]        cyclic_data_rdata          ;

// -- output
    wire                                cap_done                   ;


         
//=======================================================================================
// signal define                                                                                   
//=======================================================================================

wire               [  31: 0]        tx_data                    ;
wire               [  31: 0]        rx_data                    ;
// wire               [  31: 0]        rx_data_2                  ;

// tx data
assign tx1_idata = 'd0;
assign tx1_qdata = 'd0;
assign tx2_idata = tx_data[15: 0];
assign tx2_qdata = tx_data[31:16];

//assign tx1_idata = tx_data[15: 0];
//assign tx1_qdata = tx_data[31:16];
//assign tx2_idata = 'd0;
//assign tx2_qdata = 'd0;

// rx data
//assign rx_data   = {rx1_qdata, rx1_idata};
assign rx_data   = {rx2_qdata, rx2_idata};
// assign rx_data_2 = {rx2_qdata,rx2_idata};

//***************************************************************************************
// design start from here                                                                                    
//***************************************************************************************
// Register Interface
    always @(posedge axi_gp_clk) begin
        if (axi_rst_n == 1'b0) begin
            up_wack <= 1'b0;
        end else begin
            up_wack <= up_wreq;
        end
    end

    always @(posedge axi_gp_clk) begin
        if (axi_rst_n == 1'b0) begin
            up_rack <= 'd0;
        end else begin
            up_rack <= up_rreq;
        end
    end

//write register
    always @ (posedge axi_gp_clk or negedge axi_rst_n) begin
        if(!axi_rst_n) begin
            align_en          <= 'd0;
            delay             <= 'd0;
            apc_k_i           <= 'd0;
            apc_k_q           <= 'd0;
            cap_data_cmd      <= 'd0;
            cap_len           <= 'd0;
            trigger_point     <= 'd0;
            cap_rd_addr       <= 'd0;
            // cap_data_rdata    <= 'd0;
            tx_vld            <= 'd0;
            tx_data_en        <= 'd0;
            tx_data_wr        <= 'd0;
            tx_data_addr      <= 'd0;
            tx_data_wdata     <= 'd0;
            // tx_data_rdata     <= 'd0;
            ch_sel            <= 'd0;
            dpd_en            <= 'd0;
            dpd_coe_en        <= 'd0;
            dpd_coe_wr        <= 'd0;
            dpd_coe_addr      <= 'd0;
            dpd_coe_wdata     <= 'd0;
            // dpd_coe_rdata     <= 'd0;
            // dpd_out           <= 'd0;
            cyclic_en         <= 'd0;
            cyclic_data_en    <= 'd0;
            cyclic_data_wr    <= 'd0;
            cyclic_data_addr  <= 'd0;
            cyclic_data_wdata <= 'd0;
            // cyclic_data_rdata <= 'd0;
            // cap_done          <= 'd0;
        end
        else if(up_wreq) begin
            case(up_waddr[15:2])
                8'd00 : align_en          <= up_wdata[   0: 0];
                8'd01 : delay             <= up_wdata[   9: 0];
                8'd02 : apc_k_i           <= up_wdata[  31: 0];
                8'd03 : apc_k_q           <= up_wdata[  31: 0];
                8'd04 : cap_data_cmd      <= up_wdata[   5: 0];
                8'd05 : cap_len           <= up_wdata[  15: 0];
                8'd06 : trigger_point     <= up_wdata[  31: 0];
                8'd07 : cap_rd_addr       <= up_wdata[  15: 0];
                // 8'd08 : cap_data_rdata    <= up_wdata[  31: 0];
                8'd09 : tx_vld            <= up_wdata[   0: 0];
                8'd10 : tx_data_en        <= up_wdata[   0: 0];
                8'd11 : tx_data_wr        <= up_wdata[   0: 0];
                8'd12 : tx_data_addr      <= up_wdata[  15: 0];
                8'd13 : tx_data_wdata     <= up_wdata[  31: 0];
                // 8'd14 : tx_data_rdata     <= up_wdata[  31: 0];
                8'd15 : ch_sel            <= up_wdata[   2: 0];
                8'd16 : dpd_en            <= up_wdata[   0: 0];
                8'd17 : dpd_coe_en        <= up_wdata[   0: 0];
                8'd18 : dpd_coe_wr        <= up_wdata[   0: 0];
                8'd19 : dpd_coe_addr      <= up_wdata[   9: 0];
                8'd20 : dpd_coe_wdata     <= up_wdata[  15: 0];
                // 8'd21 : dpd_coe_rdata     <= up_wdata[  15: 0];
                // 8'd22 : dpd_out           <= up_wdata[  31: 0];
                8'd23 : cyclic_en         <= up_wdata[   0: 0];
                8'd24 : cyclic_data_en    <= up_wdata[   0: 0];
                8'd25 : cyclic_data_wr    <= up_wdata[   0: 0];
                8'd26 : cyclic_data_addr  <= up_wdata[  15: 0];
                8'd27 : cyclic_data_wdata <= up_wdata[  31: 0];
                // 8'd28 : cyclic_data_rdata <= up_wdata[  31: 0];
                // 8'd29 : cap_done          <= up_wdata[   0: 0];
            endcase
        end
    end

//read register

    always @ (posedge axi_gp_clk or negedge axi_rst_n) begin
        if(!axi_rst_n) begin
            up_rdata<=32'd0;
        end else if(up_rreq) begin
            case(up_raddr[15:2])
                8'd00 : up_rdata <= align_en          ;
                8'd01 : up_rdata <= delay             ;
                8'd02 : up_rdata <= apc_k_i           ;
                8'd03 : up_rdata <= apc_k_q           ;
                8'd04 : up_rdata <= cap_data_cmd      ;
                8'd05 : up_rdata <= cap_len           ;
                8'd06 : up_rdata <= trigger_point     ;
                8'd07 : up_rdata <= cap_rd_addr       ;
                8'd08 : up_rdata <= cap_data_rdata    ;
                8'd09 : up_rdata <= tx_vld            ;
                8'd10 : up_rdata <= tx_data_en        ;
                8'd11 : up_rdata <= tx_data_wr        ;
                8'd12 : up_rdata <= tx_data_addr      ;
                8'd13 : up_rdata <= tx_data_wdata     ;
                8'd14 : up_rdata <= tx_data_rdata     ;
                8'd15 : up_rdata <= ch_sel            ;
                8'd16 : up_rdata <= dpd_en            ;
                8'd17 : up_rdata <= dpd_coe_en        ;
                8'd18 : up_rdata <= dpd_coe_wr        ;
                8'd19 : up_rdata <= dpd_coe_addr      ;
                8'd20 : up_rdata <= dpd_coe_wdata     ;
                8'd21 : up_rdata <= dpd_coe_rdata     ;
                8'd22 : up_rdata <= dpd_out           ;
                8'd23 : up_rdata <= cyclic_en         ;
                8'd24 : up_rdata <= cyclic_data_en    ;
                8'd25 : up_rdata <= cyclic_data_wr    ;
                8'd26 : up_rdata <= cyclic_data_addr  ;
                8'd27 : up_rdata <= cyclic_data_wdata ;
                8'd28 : up_rdata <= cyclic_data_rdata ;
                8'd29 : up_rdata <= cap_done          ;
                default : up_rdata <= 32'haabbccdd ;
            endcase
        end
    end


//---------------------------------------------------------------------------------------
// instantiate data ctrl module                                                                                    
//---------------------------------------------------------------------------------------

data_ctrl u_data_ctrl(
    .clk_axi                            (axi_gp_clk                ),
    .clk_ad9371                         (rx_sample_clk             ),
    .rst_n                              (axi_rst_n                 ),
    // ad9371 data
    .tx_data                            (tx_data                   ),
    .rx_data                            (rx_data                   ),
    // time delay, amplitude and phase align  
    .align_en                           (align_en                  ),
    .delay                              (delay                     ),
    .apc_k_i                            (apc_k_i                   ),
    .apc_k_q                            (apc_k_q                   ),
    // cap data
    .cap_data_cmd                       (cap_data_cmd              ),
    .cap_len                            (cap_len                   ),
    .trigger_point                      (trigger_point             ),
    .cap_rd_addr                        (cap_rd_addr               ),
    .cap_data_rdata                     (cap_data_rdata            ),
    // tx data 
    .tx_vld                             (tx_vld                    ),
    .tx_data_en                         (tx_data_en                ),
    .tx_data_wr                         (tx_data_wr                ),
    .tx_data_addr                       (tx_data_addr              ),
    .tx_data_wdata                      (tx_data_wdata             ),
    .tx_data_rdata                      (tx_data_rdata             ),
    // dpd
    .ch_sel                             (ch_sel                    ),
    .dpd_en                             (dpd_en                    ),
    .dpd_coe_en                         (dpd_coe_en                ),
    .dpd_coe_wr                         (dpd_coe_wr                ),
    .dpd_coe_addr                       (dpd_coe_addr              ),
    .dpd_coe_wdata                      (dpd_coe_wdata             ),
    .dpd_coe_rdata                      (dpd_coe_rdata             ),
    .dpd_out                            (dpd_out                   ),
    // cyclic
    .cyclic_en                          (cyclic_en                 ),
    .cyclic_data_en                     (cyclic_data_en            ),
    .cyclic_data_wr                     (cyclic_data_wr            ),
    .cyclic_data_addr                   (cyclic_data_addr          ),
    .cyclic_data_wdata                  (cyclic_data_wdata         ),
    .cyclic_data_rdata                  (cyclic_data_rdata         ),
    // -- output
    .cap_done                           (cap_done                  )
);



endmodule