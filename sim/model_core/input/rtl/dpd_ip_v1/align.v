`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE     
// VSCODE plug-in version: Verilog-Hdl-Format-2.8.20240817
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Please Write Company name
// All rights reserved     
// File name:              
// Last modified Date:     2024/12/03 20:34:41
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Please Write You Name 
// Created date:           2024/12/03 20:34:41
// mail      :             Please Write mail 
// Version:                V1.0
// TEXT NAME:              align.v
// PATH:                   D:\postgraduate\competition\BMRA9009_Project\pl\ip_repo\src\align.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module align(
    clk                        ,
    rst_n                      ,
    align_en                   ,
    delay                      ,
    tx_data                    ,
    rx_data                    ,
    ps_phase_k_i               ,
    ps_phase_k_q               ,
    tx_delay                   ,
    tx_time_align              ,
    rx_phase_align             
);
    // io port
    input                               clk                        ;
    input                               rst_n                      ;
    input                               align_en                   ;
    input              [  31: 0]        delay                      ;
    input              [  31: 0]        tx_data                    ;// (16, 1) + j (16, 1)
    input              [  31: 0]        rx_data                    ;// (16, 1) + j (16, 1)
    input       signed [  31: 0]        ps_phase_k_i               ;// (32, 8)
    input       signed [  31: 0]        ps_phase_k_q               ;// (32, 8)

    output             [  31: 0]        tx_delay                   ;
    output             [  31: 0]        tx_time_align              ;// return to python
    output             [  31: 0]        rx_phase_align             ;

    // singnal define

    wire                                align_en_pos               ;
    reg                                 align_en_d1                ;
    reg                [   9: 0]        delay_align                ;
    reg      signed    [  31: 0]        k_i                        ;  // (32, 8)
    reg      signed    [  31: 0]        k_q                        ;  // (32, 8)
    wire     signed    [  15: 0]        rx_data_i                  ;// (16, 1)
    wire     signed    [  15: 0]        rx_data_q                  ;// (16, 1)
    reg      signed    [  48: 0]        phase_align_i_L            ;// (49, 10)
    reg      signed    [  48: 0]        phase_align_q_L            ;// (49, 10)
    reg      signed    [  15: 0]        phase_align_i              ;// (16, 1)
    reg      signed    [  15: 0]        phase_align_q              ;// (16, 1)


    reg                [  31: 0]        delay_data_x        [0:1023]  ;

    //---------------------------------------------------------------------------------------
    //  design start from here                                                                                   
    //---------------------------------------------------------------------------------------

    // update k and delay
    assign align_en_pos = align_en & (~align_en_d1);

    always @(posedge clk)begin
        if(!rst_n) begin
            align_en_d1 <= 1'b0;
        end
        else begin
            align_en_d1 <= align_en;
        end
    end
    
    always @(posedge clk ) begin
        if(!rst_n) begin
            k_i         <= 'd0;
            k_q         <= 'd0;
            delay_align <= 'd0;
        end
        else if(align_en_pos) begin
            k_i         <= ps_phase_k_i;
            k_q         <= ps_phase_k_q;
            delay_align <= delay;
        end
    end

    // ---- time delay align ----// 

    always @(posedge clk)begin: time_align_delay
        integer ii;
        if(!rst_n) begin
            for (ii = 0; ii < 1024; ii = ii + 1) begin
                delay_data_x[ii] <= 0;
            end
        end
        else begin
            for (ii = 1023; ii > 0; ii = ii - 1) begin
                delay_data_x[ii] <= delay_data_x[ii - 1];
            end
            delay_data_x[0] <= tx_data;
        end
    end
    // return tx_time_align to python , make correlation and validate whether the result is right 
    assign tx_delay       = delay_data_x[65]; 
    assign tx_time_align  = delay_data_x[delay_align];
     
    // ---- phase align ----// begin
    // assign k_rx_ii = rx_data_i * k_i; //(16, 1) * (32, 8) = (48, 9)
    // assign k_rx_qq = rx_data_q * k_q; //(16, 1) * (32, 8) = (48, 9)
    // assign k_rx_qq = rx_data_i * k_q; //(16, 1) * (32, 8) = (48, 9)
    // assign k_rx_qi = rx_data_q * k_i; //(16, 1) * (32, 8) = (48, 9)

    assign                              rx_data_i                 = rx_data[15:0];
    assign                              rx_data_q                 = rx_data[31:16];
    
    always @(posedge clk) begin
        if(!rst_n) begin
            phase_align_i_L <= 0;
            phase_align_q_L <= 0;
        end
        else begin
            phase_align_i_L <= rx_data_i * k_i - rx_data_q * k_q; //(48, 9) + (48, 9) = (49, 10)
            phase_align_q_L <= rx_data_i * k_q + rx_data_q * k_i;
        end
    end

    // ---- phase align ----// end
    
    assign rx_phase_align = {phase_align_q, phase_align_i};
    // data saturate(49,10) -> (16,1)
    always @(*) begin
        if(phase_align_i_L[48]) begin
            if(phase_align_i_L[47:39] == 9'h1ff) begin
                phase_align_i = phase_align_i_L[39-:16];
            end
            else begin
                phase_align_i = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(phase_align_i_L[47:39] == 9'h000) begin
                phase_align_i = phase_align_i_L[39-:16];
            end
            else begin
                phase_align_i = {1'b0, {15{1'b1}}};
            end
        end

        if(phase_align_q_L[48]) begin
            if(phase_align_q_L[47:39] == 9'h1ff) begin
                phase_align_q = phase_align_q_L[39-:16];
            end
            else begin
                phase_align_q = {1'b1, {15{1'b0}}};
            end
        end
        else begin
            if(phase_align_q_L[47:39] ==  9'h000) begin
                phase_align_q = phase_align_q_L[39-:16];
            end
            else begin
                phase_align_q = {1'b0, {15{1'b1}}};
            end
        end
    end                                      

   
                                                                
endmodule