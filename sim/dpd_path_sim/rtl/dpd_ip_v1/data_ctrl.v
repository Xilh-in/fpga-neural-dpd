`timescale 1ns / 1ps


module data_ctrl(
    input                               clk_axi                    ,
    input                               clk_ad9371                 ,
    input                               rst_n                      ,
    // ad9371 data
    output             [  31: 0]        tx_data                    ,
    input              [  31: 0]        rx_data                    ,

    // time delay, amplitude and phase align  
    input                               align_en                   ,
    input              [   9: 0]        delay                      ,
    input       signed [  31: 0]        apc_k_i                    ,
    input       signed [  31: 0]        apc_k_q                    ,

    // cap data
    input              [   5: 0]        cap_data_cmd               ,
    input              [  15: 0]        cap_len                    ,
    input              [  31: 0]        trigger_point              ,
    input              [  15: 0]        cap_rd_addr                ,
    output reg         [  31: 0]        cap_data_rdata             ,

    // tx data 
    input                               tx_vld                     ,
    input                               tx_data_en                 ,
    input                               tx_data_wr                 ,
    input              [  15: 0]        tx_data_addr               ,
    input              [  31: 0]        tx_data_wdata              ,
    output             [  31: 0]        tx_data_rdata              ,

    // dpd
    input              [   2: 0]        ch_sel                     ,
    input                               dpd_en                     ,
    input                               dpd_coe_en                 ,
    input                               dpd_coe_wr                 ,
    input              [   9: 0]        dpd_coe_addr               ,
    input              [  15: 0]        dpd_coe_wdata              ,
    output             [  15: 0]        dpd_coe_rdata              ,
    (* MARK_DEBUG="true" *)output reg         [  31: 0]        dpd_out                    ,
    
    // cyclic
    input                               cyclic_en                  ,
    input                               cyclic_data_en             ,
    input                               cyclic_data_wr             ,
    input              [  15: 0]        cyclic_data_addr           ,
    input              [  31: 0]        cyclic_data_wdata          ,
    output             [  31: 0]        cyclic_data_rdata          ,
    
    // -- output
    output                              cap_done                    
    );
    // test
// parameter define
    parameter                           DWIDTH                    = 32    ;
    parameter                           DATA_LENGTH               = 17536 ;
    parameter                           ADDR_BITS                 = 16    ;

//---------------------------------------------------------------------------------------
// Design Start from here                                                                                    
//---------------------------------------------------------------------------------------
    reg                                 tx_vld_axi2ad9371          ;
    (* MARK_DEBUG="true" *)reg                                 tx_vld_ad9371              ;
    (* MARK_DEBUG="true" *)reg                [  66: 0]        tx_vld_ad9371_dly          ;
    (* MARK_DEBUG="true" *)wire               [DWIDTH-1: 0]    tx_ram_out                 ;
    reg                [DWIDTH-1: 0]    tx_data_d1                 ;
    reg                [DWIDTH-1: 0]    rx_data_d1                 ;
// wire define ram read out
    wire               [  31: 0]        tx_time_align              ;
    wire               [  31: 0]        rx_phase_align             ;


// ps ctrl signal
    wire                                ps_cap_en                  ;
    reg                                 ps_cap_en_axi2ad9371       ;
    reg                                 ps_cap_en_axi2ad9371_d1    ;
    reg                                 ps_cap_en_axi2ad9371_d2    ;
    wire                                ps_cap_en_pos              ;

    wire                                ps_ack                     ;
    reg                                 ps_ack_axi2ad9371          ;
    reg                                 ps_ack_axi2ad9371_d1       ;
    reg                                 ps_ack_axi2ad9371_d2       ;
    wire                                ps_ack_ps_ad9371_pos       ;


    wire                                data_rd_en                 ;
    wire               [   2: 0]        ram_index                  ;


// pl ctrl signal
    reg                [  15: 0]        tx_addr                    ;
    reg                [  14: 0]        cnt_trigger_sync           ;
    reg                                 cap_en_ad9371              ;

    reg                                 cap_A_en                   ;
    wire                                cap_A_done                 ;
    reg                [  15: 0]        cap_A_addr                 ;

    reg                                 cap_B_en                   ;
    wire                                cap_B_done                 ;
    reg                [  15: 0]        cap_B_addr                 ;

    reg                                 cap_C_en                   ;
    reg                                 cap_C_done                 ;
    reg                [  15: 0]        cap_C_addr                 ;

    wire                                cap_D_en                   ;
    wire                                cap_D_done                 ;
    wire               [  15: 0]        cap_D_addr                 ;

    reg                                 cap_E_en                   ;
    reg                                 cap_E_done                 ;
    reg                [  15: 0]        cap_E_addr                 ;

    reg                                 cap_F_en                   ;
    wire                                cap_F_done                 ;
    reg                [  15: 0]        cap_F_addr                 ;

    wire                                cap_G_en                   ;
    wire                                cap_G_done                 ;
    wire               [  15: 0]        cap_G_addr                 ;
    reg                [  31: 0]        node_G_data                ;

    reg                                 cap_H_en                   ;
    reg                                 cap_H_done                 ;
    reg                [  15: 0]        cap_H_addr                 ;
    
// ram read ctrl
    reg rd_en_A; 
    reg rd_en_B;
    reg rd_en_C;
    reg rd_en_D;
    reg rd_en_E;
    reg rd_en_F;
    reg rd_en_G;
    reg rd_en_H;

    wire [DWIDTH-1 :0] rd_data_A;
    wire [DWIDTH-1 :0] rd_data_B;
    wire [DWIDTH-1 :0] rd_data_C;
    wire [DWIDTH-1 :0] rd_data_D;
    wire [DWIDTH-1 :0] rd_data_E;
    wire [DWIDTH-1 :0] rd_data_F;
    wire [DWIDTH-1 :0] rd_data_G;
    wire [DWIDTH-1 :0] rd_data_H;

//100M-reg -> en
    reg                                 align_en_d1                ;
    reg                                 align_en_d2                ;
    reg                                 align_en_d3                ;

// dpd
    reg                                 dpd_en_d1                  ;
    reg                                 dpd_en_d2                  ;
    reg                                 dpd_coe_en_d1              ;
    reg                                 dpd_coe_en_d2              ;
    reg                                 dpd_coe_wr_d1              ;
    reg                                 dpd_coe_wr_d2              ;
    wire     signed    [  15: 0]        dpd_in_i                   ;
    wire     signed    [  15: 0]        dpd_in_q                   ;
    wire               [  31: 0]        tx_dealy                   ;
    (* MARK_DEBUG="true" *)wire     signed    [  15: 0]        tx_dealy_i                 ;
    (* MARK_DEBUG="true" *)wire     signed    [  15: 0]        tx_dealy_q                 ;
    reg      signed    [  15: 0]        tx_dealy_i_d1              ;
    reg      signed    [  15: 0]        tx_dealy_q_d1              ;
    reg      signed    [  16: 0]        yn_out_L_i                 ;
    reg      signed    [  16: 0]        yn_out_L_q                 ;
    reg      signed    [  15: 0]        yn_out_i                   ;
    reg      signed    [  15: 0]        yn_out_q                   ;
    wire               [  31: 0]        err                        ;
    reg      signed    [  16: 0]        err_L_i                    ;
    reg      signed    [  16: 0]        err_L_q                    ;
    reg      signed    [  15: 0]        err_i                      ;
    reg      signed    [  15: 0]        err_q                      ;

// cyclic
    reg                                 cyclic_rd_en               ;
    reg                [  15: 0]        cyclic_rd_addr             ;
    wire               [  31: 0]        cyclic_out                 ;
    reg      signed    [  16: 0]        dn_out_L_i                 ;
    reg      signed    [  16: 0]        dn_out_L_q                 ;
    reg      signed    [  15: 0]        dn_out_i                   ;
    reg      signed    [  15: 0]        dn_out_q                   ;

// output
    wire                                dout_vd                    ;
    wire     signed    [  15: 0]        model_out_i                ;
    wire     signed    [  15: 0]        model_out_q                ;
    reg      signed    [  15: 0]        model_out_i_d1             ;
    reg      signed    [  15: 0]        model_out_q_d1             ;
    reg      signed    [  15: 0]        cyclic_out_i_d1            ;
    reg      signed    [  15: 0]        cyclic_out_q_d1            ;
    
//---------------------------------------------------------------------------------------
// send TX data to ad9371                                                                                    
//---------------------------------------------------------------------------------------
// assign tx_data = tx_vld_ad9371_dly[66]? tx_ram_out : 'd0;
assign tx_data = tx_vld_ad9371_dly[66]? dpd_out : 'd0;

// -- tx vld cdc
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            tx_vld_axi2ad9371  <= 1'b0;
            tx_vld_ad9371      <= 1'b0;
            tx_vld_ad9371_dly  <=  'd0;
        end
        else begin
            tx_vld_axi2ad9371  <= tx_vld;
            tx_vld_ad9371      <= tx_vld_axi2ad9371;
            tx_vld_ad9371_dly  <= {tx_vld_ad9371_dly[65:0], tx_vld_ad9371};
        end
    end       
    
    always @(posedge clk_ad9371 ) begin
        if(!rst_n) begin
            tx_addr <= 16'd0;
        end
        else if(tx_addr == DATA_LENGTH - 1) begin
            tx_addr <= 16'd0;
        end
        else if(tx_vld_ad9371) begin
            tx_addr <= tx_addr + 1'b1;
        end
        else begin
            tx_addr <= 16'd0;
        end
    end

//---------------------------------------------------------------------------------------
// ps ctrl signal transfer (from clk_axi to clk_ad9371)                                                                                    
//---------------------------------------------------------------------------------------
assign                              ps_ack                    = cap_data_cmd[5];
assign                              ps_cap_en                 = cap_data_cmd[4];
assign                              data_rd_en                = cap_data_cmd[3];
assign                              ram_index                 = cap_data_cmd[2:0];

// --- cap_en cdc --- //
    assign ps_cap_en_pos = ps_cap_en_axi2ad9371_d1 & (~ps_cap_en_axi2ad9371_d2);

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            ps_cap_en_axi2ad9371     <= 1'b0;
            ps_cap_en_axi2ad9371_d1  <= 1'b0;
            ps_cap_en_axi2ad9371_d2  <= 1'b0;
        end
        else begin
            ps_cap_en_axi2ad9371     <= ps_cap_en;
            ps_cap_en_axi2ad9371_d1  <= ps_cap_en_axi2ad9371;
            ps_cap_en_axi2ad9371_d2  <= ps_cap_en_axi2ad9371_d1;
        end
    end


// --- ps_ack cdc --- //
    assign ps_ack_ad9371_pos = ps_ack_axi2ad9371_d1 & (~ps_ack_axi2ad9371_d2);

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            ps_ack_axi2ad9371     <= 1'b0;
            ps_ack_axi2ad9371_d1  <= 1'b0;
            ps_ack_axi2ad9371_d2  <= 1'b0;
        end
        else begin
            ps_ack_axi2ad9371     <= ps_ack;
            ps_ack_axi2ad9371_d1  <= ps_ack_axi2ad9371;
            ps_ack_axi2ad9371_d2  <= ps_ack_axi2ad9371_d1;
        end
    end

//---------------------------------------------------------------------------------------
// data capture (trigger)
// tx length = 17536  (cycle send mode)                                                                                           
//---------------------------------------------------------------------------------------
// --- generate cap enable signal at clkad9371 --- //
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_en_ad9371 <= 1'b0;
        end
        else if(ps_cap_en_pos) begin
            cap_en_ad9371 <= 1'b1;
        end
        else if(ps_ack_ad9371_pos) begin
            cap_en_ad9371 <= 1'b0;
        end
    end


//----generate cap_A_en signal (delay 1T)----//
    assign cap_done = cap_E_done; 

    assign cap_A_done = (cap_A_addr == cap_len);

    always @(posedge clk_ad9371) begin                                        
        if(!rst_n)                               
            cap_A_en <= 1'b0;  
        else if (cap_en_ad9371) begin
            if(cap_A_done) begin
                cap_A_en <= 1'b0;
            end
            else if(tx_addr == trigger_point[15:0]) begin  // cnt
                cap_A_en <= 1'b1; 
            end
        end 
        else begin
            cap_A_en <= 1'b0;
        end                                                                                          
    end  

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_A_addr <= 'd0;
        end
        else if(cap_en_ad9371) begin
            if(cap_A_done) begin
                cap_A_addr <= cap_A_addr;
            end
            else if(cap_A_en) begin
                cap_A_addr <= cap_A_addr + 1'b1;
            end
        end
        else begin
            cap_A_addr <= 'd0;
        end
    end

// // tx/rx data delay 1T align to cap_A_en signal
//     always @(posedge clk_ad9371) begin
//         if(!rst_n) begin
//             rx_data_d1 <= 'd0;
//         end
//         else begin
//             rx_data_d1 <= rx_data;
//         end
//     end

//---- mutli point delay capture ----//
    always @(posedge clk_ad9371)begin                                           
        if(!rst_n)  begin
            cnt_trigger_sync <= 'd0;
        end
        else if (cnt_trigger_sync == DATA_LENGTH - 1) begin
            cnt_trigger_sync <= 'd0;
        end                                                                                    
        else if(cap_A_en) begin
            cnt_trigger_sync <= cnt_trigger_sync + 1'd1;
        end    
        else if(cnt_trigger_sync != 'd0) begin
            cnt_trigger_sync <= cnt_trigger_sync + 1'b1;
        end
        else begin
            cnt_trigger_sync <= 'd0;  
        end              
    end 

// Point B cap enable signal
    assign cap_B_done = (cap_B_addr == cap_len);

    always @(posedge clk_ad9371)begin                                           
        if(!rst_n)  begin
            cap_B_en <= 'd0;
        end   
        else if(cap_en_ad9371) begin
            if (cap_B_done) begin
                cap_B_en <= 'd0;
            end                                                                              
            else if(cap_A_en && cnt_trigger_sync == {5'd0, delay}) begin 
                cap_B_en <= 1'd1;
            end  
        end    
        else begin
            cap_B_en <= 1'b0;
        end                  
    end  

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_B_addr <= 'd0;
        end
        else if(cap_en_ad9371) begin
            if(cap_B_done) begin
                cap_B_addr <= cap_B_addr;
            end
            else if(cap_B_en) begin
                cap_B_addr <= cap_B_addr + 1'b1;  
            end
        end
        else begin
            cap_B_addr <= 'd0;
        end
    end

// tx/rx data delay 1T align to cap_B_en
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            tx_data_d1 <= 'd0;
            rx_data_d1 <= 'd0;
        end
        else begin
            tx_data_d1 <= tx_ram_out;
            rx_data_d1 <= rx_data;
        end
    end


// Point C/D cap_en signal
    assign cap_D_en   = cap_C_en;
    assign cap_D_done = cap_C_done;
    assign cap_D_addr = cap_C_addr;

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_C_en <= 1'b0;
        end
        else begin
            cap_C_en <= cap_B_en;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_C_done <= 'd0;
            cap_C_addr <= 'd0;
        end
        else begin
            cap_C_done <= cap_B_done;
            cap_C_addr <= cap_B_addr;
        end
    end

// Point E cap_en signal
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_E_en <= 1'b0;
        end
        else begin
            cap_E_en <= cap_C_en;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_E_done <= 'd0;
            cap_E_addr <= 'd0;
        end
        else begin
            cap_E_done <= cap_C_done;
            cap_E_addr <= cap_C_addr;
        end
    end

// Point F/G cap_en signal
    assign cap_G_en   = cap_F_en;
    assign cap_G_done = cap_F_done;
    assign cap_G_addr = cap_F_addr;

    assign cap_F_done = (cap_F_addr == cap_len);

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_F_en <= 1'b0;
        end
        else if(cap_en_ad9371) begin
            if (cap_F_done) begin
                cap_F_en <= 'd0;
            end                                                                              
            else if(cnt_trigger_sync == 'd66) begin 
                cap_F_en <= 1'd1;
            end  
        end    
        else begin
            cap_F_en <= 1'b0;
        end    
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_F_addr <= 'd0;
        end
        else if(cap_en_ad9371) begin
            if(cap_F_done) begin
                cap_F_addr <= cap_F_addr;
            end
            else if(cap_F_en) begin
                cap_F_addr <= cap_F_addr + 1'b1;  
            end
        end
        else begin
            cap_F_addr <= 'd0;
        end
    end

// Point H cap_en signal
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_H_en <= 1'b0;
        end
        else begin
            cap_H_en <= cap_F_en;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cap_H_done <= 'd0;
            cap_H_addr <= 'd0;
        end
        else begin
            cap_H_done <= cap_F_done;
            cap_H_addr <= cap_F_addr;
        end
    end

// ----Triggered Sampling ----//end

//---------------------------------------------------------------------------------------
// read data from ram                                                                                    
//---------------------------------------------------------------------------------------
    always @(posedge clk_axi) begin
        if(!rst_n) begin
            rd_en_A <= 1'b0;
            rd_en_B <= 1'b0;
            rd_en_C <= 1'b0;
            rd_en_D <= 1'b0;
            rd_en_E <= 1'b0;
            rd_en_F <= 1'b0;
            rd_en_G <= 1'b0;
            rd_en_H <= 1'b0;
        end
        else if (data_rd_en) begin
            case(ram_index) 
                3'b000: begin
                    rd_en_A        <= 1'b1;
                    cap_data_rdata <= rd_data_A;
                end

                3'b001: begin
                    rd_en_B        <= 1'b1;
                    cap_data_rdata <= rd_data_B;
                end

                3'b010: begin
                    rd_en_C        <= 1'b1;
                    cap_data_rdata <= rd_data_C;
                end

                3'b011: begin
                    rd_en_D        <= 1'b1;
                    cap_data_rdata <= rd_data_D;
                end

                3'b100: begin
                    rd_en_E        <= 1'b1;
                    cap_data_rdata <= rd_data_E;
                end

                3'b101: begin
                    rd_en_F        <= 1'b1;
                    cap_data_rdata <= rd_data_F;
                end

                3'b110: begin
                    rd_en_G        <= 1'b1;
                    cap_data_rdata <= rd_data_G;
                end

                3'b111: begin
                    rd_en_H        <= 1'b1;
                    cap_data_rdata <= rd_data_H;
                end
            endcase
        end
        else begin
            rd_en_A <= 1'b0;
            rd_en_B <= 1'b0;
            rd_en_C <= 1'b0;
            rd_en_D <= 1'b0;
            rd_en_E <= 1'b0;
            rd_en_F <= 1'b0;
            rd_en_G <= 1'b0;
            rd_en_H <= 1'b0;
        end
    end

//---------------------------------------------------------------------------------------
//     cdc -> data_en and data_wr                                                                               
//---------------------------------------------------------------------------------------
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            align_en_d1 <= 1'b0;
            align_en_d2 <= 1'b0;
        end
        else begin
            align_en_d1 <= align_en;
            align_en_d2 <= align_en_d1;
        end 
    end


//---------------------------------------------------------------------------------------
// get tx data from ps                                                                                    
//---------------------------------------------------------------------------------------
// ---- data ram control ---- // end
    true_dp_ram#(
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               ) 
        )
        u_True_DP_ram_TX(
            // A port
        .clk_a                              (clk_axi                   ),
        .ena                                (tx_data_en                ),
        .wea                                (tx_data_wr                ),
        .dina                               (tx_data_wdata             ),
        .addra                              (tx_data_addr              ),
        .douta                              (tx_data_rdata             ),
            // B port
        .clk_b                              (clk_ad9371                ),
        .rd_en                              (tx_vld_ad9371             ),
        .addrb                              (tx_addr                   ),
        .doutb                              (tx_ram_out                ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               ) 
        ) u_dp_ram_A(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_A_en                  ),
        .wea                                (cap_A_en                  ),
        .dina                               (tx_ram_out                ),
        .addra                              (cap_A_addr                ),
        
        .rd_en                              (rd_en_A                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_A                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               ) 
        ) u_dp_ram_B(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_B_en                  ),
        .wea                                (cap_B_en                  ),
        .dina                               (rx_data_d1                ),
        .addra                              (cap_B_addr                ),
            
        .rd_en                              (rd_en_B                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_B                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_C(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_C_en                  ),
        .wea                                (cap_C_en                  ),
        .dina                               (rx_phase_align            ),
        .addra                              (cap_C_addr                ),
            
        .rd_en                              (rd_en_C                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_C                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_D(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_D_en                  ),
        .wea                                (cap_D_en                  ),
        .dina                               (tx_time_align             ),
        .addra                              (cap_D_addr                ),
            
        .rd_en                              (rd_en_D                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_D                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_E(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_E_en                  ),
        .wea                                (cap_E_en                  ),
        .dina                               (err                       ),
        .addra                              (cap_E_addr                ),
            
        .rd_en                              (rd_en_E                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_E                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_F(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_F_en                  ),
        .wea                                (cap_F_en                  ),
        .dina                               (tx_dealy                  ),
        .addra                              (cap_F_addr                ),
            
        .rd_en                              (rd_en_F                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_F                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_G(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_G_en                  ),
        .wea                                (cap_G_en                  ),
        .dina                               (node_G_data               ),
        .addra                              (cap_G_addr                ),
            
        .rd_en                              (rd_en_G                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_G                 ) 
    );

    dp_ram # (
        .PW_DATA                            (DWIDTH                    ),
        .PN_DEPTH                           (DATA_LENGTH               )
        ) u_dp_ram_H(
        // Write port
        .clk_wr                             (clk_ad9371                ),
        .ena                                (cap_H_en                  ),
        .wea                                (cap_H_en                  ),
        .dina                               (tx_data                   ),
        .addra                              (cap_H_addr                ),
            
        .rd_en                              (rd_en_H                   ),
        .clk_rd                             (clk_axi                   ),
        .addrb                              (cap_rd_addr               ),
        .doutb                              (rd_data_H                 ) 
    );

//---------------------------------------------------------------------------------------
// delay/APC align module                                                                                    
//---------------------------------------------------------------------------------------
    align u_align (
        .clk                                (clk_ad9371                ),
        .rst_n                              (rst_n                     ),
        .align_en                           (align_en_d2               ),
        .delay                              (delay                     ),
        .tx_data                            (tx_data_d1                ),
        .rx_data                            (rx_data_d1                ),
        .ps_phase_k_i                       (apc_k_i                   ),
        .ps_phase_k_q                       (apc_k_q                   ),
        .tx_delay                           (tx_dealy                  ),
        .tx_time_align                      (tx_time_align             ),
        .rx_phase_align                     (rx_phase_align            ) 
    );

//---------------------------------------------------------------------------------------
// DPD Desgin Start from here                                                                                    
//---------------------------------------------------------------------------------------
    assign err  = {err_q, err_i};

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            err_L_i <= 'd0;
            err_L_q <= 'd0;
        end
        else begin
            err_L_i <= $signed(rx_phase_align[15: 0]) - $signed(tx_time_align[15: 0]); // (16, 1) + (16, 1) = (17, 2)
            err_L_q <= $signed(rx_phase_align[31:16]) - $signed(tx_time_align[31:16]); // (16, 1) + (16, 1) = (17, 2)
        end
    end

    // data saturation: (17, 2) -> (16, 1)
    always @(*) begin
        if(err_L_i[16])begin
            if(err_L_i[15] == 1'b1) begin
                err_i = err_L_i[15:0];
            end
            else begin
                err_i = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(err_L_i[15] == 1'b0) begin
                err_i = err_L_i[15:0];
            end
            else begin
                err_i = {1'b0, {15{1'b1}}};
            end
        end

        if(err_L_q[16])begin
            if(err_L_q[15] == 1'b1) begin
                err_q = err_L_q[15:0];
            end
            else begin
                err_q = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(err_L_q[15] == 1'b0) begin
                err_q = err_L_q[15:0];
            end
            else begin
                err_q = {1'b0, {15{1'b1}}};
            end
        end
    end


    // dpd module
    // ctrl signal clk_axi to clkad9371
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            dpd_en_d1 <= 1'b0;
            dpd_en_d2 <= 1'b0;
        end
        else begin
            dpd_en_d1 <= dpd_en;
            dpd_en_d2 <= dpd_en_d1;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            dpd_coe_en_d1 <= 1'b0;
            dpd_coe_en_d2 <= 1'b0;
        end
        else begin
            dpd_coe_en_d1 <= dpd_coe_en;
            dpd_coe_en_d2 <= dpd_coe_en_d1;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            dpd_coe_wr_d1 <= 1'b0;
            dpd_coe_wr_d2 <= 1'b0;
        end
        else begin
            dpd_coe_wr_d1 <= dpd_coe_wr;
            dpd_coe_wr_d2 <= dpd_coe_wr_d1;
        end
    end

    assign dpd_in_i = dpd_en_d2? tx_data_d1[15: 0] : 'd0;
    assign dpd_in_q = dpd_en_d2? tx_data_d1[31:16] : 'd0;

    dpd_top u_dpd_top(
        .clk                                (clk_ad9371                ),
        .rst_n                              (rst_n                     ),
        .dpd_coe_en                         (dpd_coe_en_d2             ),
        .dpd_coe_wr                         (dpd_coe_wr_d2             ),
        .dpd_coe_addr                       (dpd_coe_addr              ),
        .dpd_coe_wdata                      (dpd_coe_wdata             ),// --- (16, 3)
        .din_vd                             (dpd_en_d2                 ),
        .xn_i                               (dpd_in_i                  ),// --- (1, 16, 15)
        .xn_q                               (dpd_in_q                  ),// --- (1, 16, 15)
        .dout_vd                            (dout_vd                   ),
        .yn_i                               (model_out_i               ),// --- (1, 20, 15)
        .yn_q                               (model_out_q               ),// --- (1, 20, 15)
        .dpd_coe_rdata                      (dpd_coe_rdata             ) // --- (16, 3)
    );

//---------------------------------------------------------------------------------------
// Cyclic Channel Desgin Start from here                                                                                    
//---------------------------------------------------------------------------------------
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cyclic_rd_en <= 1'b0;
        end
        else if(cyclic_en) begin
            if(tx_addr == 'd66) begin
                cyclic_rd_en <= 1'b1;
            end 
        end
        else begin
            cyclic_rd_en <= 1'b0;
        end
    end

    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cyclic_rd_addr <= 'd0;
        end
        else if(cyclic_rd_addr == DATA_LENGTH - 1) begin
            cyclic_rd_addr <= 'd0;
        end
        else if(cyclic_rd_en) begin
            cyclic_rd_addr <= cyclic_rd_addr + 1'b1;
        end
        else begin
            cyclic_rd_addr <= 'd0;
        end
    end

    true_dp_ram#(
        .PW_DATA        (32              ),
        .PN_DEPTH       (DATA_LENGTH     )
    )
    u_True_DP_ram_cyclic(
        // A port
        .clk_a                              (clk_axi                   ),
        .ena                                (cyclic_data_en            ),
        .wea                                (cyclic_data_wr            ),
        .dina                               (cyclic_data_wdata         ),
        .addra                              (cyclic_data_addr          ),
        .douta                              (cyclic_data_rdata         ),
        // B port
        .clk_b                              (clk_ad9371                ),
        .rd_en                              (cyclic_rd_en              ),
        .addrb                              (cyclic_rd_addr            ),
        .doutb                              (cyclic_out                ) 
    );

//---------------------------------------------------------------------------------------
// DPD_out Channel Desgin Start from here                                                                                    
//---------------------------------------------------------------------------------------

    assign tx_dealy_i = tx_dealy[15: 0];
    assign tx_dealy_q = tx_dealy[31:16];

    always @(*) begin
        case (ch_sel)
            3'b000:  begin
                dpd_out     = {   tx_dealy_q_d1,   tx_dealy_i_d1};
                node_G_data = {      tx_dealy_q,      tx_dealy_i};
            end
   
            3'b001:  begin
                dpd_out     = {        yn_out_q,        yn_out_i};
                node_G_data = {  model_out_q_d1,  model_out_i_d1};
            end
   
            3'b010:  begin 
                dpd_out     = {  model_out_q_d1,  model_out_i_d1};
                node_G_data = {     model_out_q,     model_out_i};
            end 
                
 
            3'b011:  begin
                dpd_out     = {        dn_out_q,        dn_out_i};
                node_G_data = cyclic_out;
            end 
 
            3'b100:  begin
                dpd_out     = { cyclic_out_q_d1, cyclic_out_i_d1};
                node_G_data = cyclic_out;
            end 

            default: begin 
                dpd_out     = {  tx_dealy_q_d1,  tx_dealy_i_d1};
                node_G_data = {     tx_dealy_q,     tx_dealy_i};
            end
        endcase
    end

    // --- scene 0 :tx
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            tx_dealy_i_d1 <= 'd0;
            tx_dealy_q_d1 <= 'd0;
        end
        else begin
            tx_dealy_i_d1 <= tx_dealy_i;
            tx_dealy_q_d1 <= tx_dealy_q;
        end
    end                                        

    // --- scene 1 :tx - model_out 
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            yn_out_L_i <= 'd0;
            yn_out_L_q <= 'd0;
        end
        else if(dout_vd_d1) begin
            yn_out_L_i <= tx_dealy_i - model_out_i_d1;
            yn_out_L_q <= tx_dealy_q - model_out_q_d1;
        end
        else begin
            yn_out_L_i <= tx_dealy_i;
            yn_out_L_q <= tx_dealy_q;
        end
    end

    // data saturation: (17, 2) -> (16, 1)
    always @(*) begin
        if(yn_out_L_i[16])begin
            if(yn_out_L_i[15] == 1'b1) begin
                yn_out_i = yn_out_L_i[15:0];
            end
            else begin
                yn_out_i = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(yn_out_L_i[15] == 1'b0) begin
                yn_out_i = yn_out_L_i[15:0];
            end
            else begin
                yn_out_i = {1'b0, {15{1'b1}}};
            end
        end

        if(yn_out_L_q[16])begin
            if(yn_out_L_q[15] == 1'b1) begin
                yn_out_q = yn_out_L_q[15:0];
            end
            else begin
                yn_out_q = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(yn_out_L_q[15] == 1'b0) begin
                yn_out_q = yn_out_L_q[15:0];
            end
            else begin
                yn_out_q = {1'b0, {15{1'b1}}};
            end
        end
    end

    reg dout_vd_d1; // Match the existing one-clock model delay.

    // --- scene 2 : model_out 
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            model_out_i_d1 <= 'd0;
            model_out_q_d1 <= 'd0;
            dout_vd_d1 <= 1'b0;
        end
        else begin
            model_out_i_d1 <= model_out_i;
            model_out_q_d1 <= model_out_q;
            dout_vd_d1 <= dout_vd;
        end
    end
    // --- scene 3 : tx - cyclic_out 
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            dn_out_L_i <= 'd0;
            dn_out_L_q <= 'd0;
        end
        else if(cyclic_rd_en) begin
            dn_out_L_i <= tx_dealy_i - $signed(cyclic_out[15: 0]);
            dn_out_L_q <= tx_dealy_q - $signed(cyclic_out[31:16]);
        end
        else begin
            dn_out_L_i <= tx_dealy_i;
            dn_out_L_q <= tx_dealy_q;
        end
    end

    // data saturation: (17, 2) -> (16, 1)
    always @(*) begin
        if(dn_out_L_i[16])begin
            if(dn_out_L_i[15] == 1'b1) begin
                dn_out_i = dn_out_L_i[15:0];
            end
            else begin
                dn_out_i = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(dn_out_L_i[15] == 1'b0) begin
                dn_out_i = dn_out_L_i[15:0];
            end
            else begin
                dn_out_i = {1'b0, {15{1'b1}}};
            end
        end

        if(dn_out_L_q[16])begin
            if(dn_out_L_q[15] == 1'b1) begin
                dn_out_q = dn_out_L_q[15:0];
            end
            else begin
                dn_out_q = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(dn_out_L_q[15] == 1'b0) begin
                dn_out_q = dn_out_L_q[15:0];
            end
            else begin
                dn_out_q = {1'b0, {15{1'b1}}};
            end
        end
    end


     // --- scene 4 : cylic out 
    always @(posedge clk_ad9371) begin
        if(!rst_n) begin
            cyclic_out_i_d1 <= 'd0;
            cyclic_out_q_d1 <= 'd0;
        end
        else begin
            cyclic_out_i_d1 <= $signed(cyclic_out[15: 0]);
            cyclic_out_q_d1 <= $signed(cyclic_out[31:16]);
        end
    end

endmodule
 

