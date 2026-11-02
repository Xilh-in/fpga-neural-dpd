// -----------------------------------------------------------------------------
// --- expcnn module
// --- NN Design: L1(LL CNN1d_0) + L2(NL EXP_Core) + L3(LL FC Net)    
// --- CNN1d_0:1-D CNN (1 channel to 3 channels)  CNN1d_1:1-D CNN (3 channel to 1 channels)
// --- delay 65 T
// -----------------------------------------------------------------------------
module expcnn (
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,
    input  wire                         din_vd                     ,
    input  wire signed [  15: 0]        xn_i                       ,
    input  wire signed [  15: 0]        xn_q                       ,
    input  wire        [576*16-1: 0]    expcnn_para                , 


// --- linear_layer_0 signal --- //]
    output wire                         L1_vd      [0:6]           , 
    output wire signed [  15: 0]        L1_out_i   [0:6]           , 
    output wire signed [  15: 0]        L1_out_q   [0:6]           , 

// --- nonlinear_layer signal --- //]
    output wire                         L2_vd      [0:6]           , 
    output wire signed [  15: 0]        L2_out_i   [0:6]           , 
    output wire signed [  15: 0]        L2_out_q   [0:6]           , 

// --- linear_layer_1 signal --- //]
    output wire                         L3_vd                      , 
    output wire signed [  15: 0]        L3_out_i                   , 
    output wire signed [  15: 0]        L3_out_q                   

// --- model out signal ---//          
    //output coredata
    // grad_1,
    // grad_0_i,
    // grad_0_q,
    // f2,
    // f0,
    // grad_2_i,
    // grad_2_q,
);


// --- model coe
wire [(21+1)*2*16-1:0] L1_coe [0:6];
wire [     9*4*16-1:0] L2_coe [0:6];
wire [       2*16-1:0] L3_coe [0:7];

// --- load model coe
genvar ii, jj;
generate

    assign L3_coe[7] = expcnn_para[(  2*8+560)*16-1 -: 2*16]; 

    for (ii=0; ii<7; ii=ii+1) begin
        assign L1_coe[ii] = expcnn_para[ (21+1)*2*(ii+1)*16-1 -: (21+1)*2*16];
        assign L2_coe[ii] = expcnn_para[(9*4*(ii+1)+308)*16-1 -:      9*4*16];  
        assign L3_coe[ii] = expcnn_para[(  2*(ii+1)+560)*16-1 -:        2*16];  
    end
endgenerate

linear_layer_0 u_Linear_layer_0 (
    .clk           (clk                                  ),
    .rst_n         (rst_n                                ),
    .din_vd        (din_vd                               ),
    .xn_i          (xn_i                                 ),
    .xn_q          (xn_q                                 ),
    .filt_para     (L1_coe                               ),
    .L_out_vd      (L1_vd                                ),
    .L_out_i       (L1_out_i                             ),
    .L_out_q       (L1_out_q                             )
);  

nonlinear_layer u_NonLinear_layer (
    .clk           (clk                                  ),
    .rst_n         (rst_n                                ),
    .din_vd        (L1_vd                                ),
    .NL_input_i    (L1_out_i                             ),
    .NL_input_q    (L1_out_q                             ),
    .NL_para       (L2_coe                               ),
    .NL_out_vd     (L2_vd                                ),
    .NL_out_i      (L2_out_i                             ),
    .NL_out_q      (L2_out_q                             )
);

linear_layer_1 u_Linear_layer_1 (
    .clk           (clk                                  ),
    .rst_n         (rst_n                                ),
    .din_vd        (L2_vd                                ),
    .xn_i          (L2_out_i                             ),
    .xn_q          (L2_out_q                             ),
    .filt_para     (L3_coe                               ),
    .L_out_vd      (L3_vd                                ),
    .L_out_i       (L3_out_i                             ),
    .L_out_q       (L3_out_q                             )
);

    // integer fid01;
    // integer fid02;
    // integer fid03;
    // integer fid04;
    // integer fid05;
    // integer fid06;
    // integer fid07;
    // integer fid08;
    // integer fid09;
    // integer fid10;
    // integer fid11;
    // integer fid12;
    // integer fid13;
    // integer fid14;
    // integer fid15;
    // integer fid16;
    // initial begin
    //     fid01 = $fopen("./sim_outdata/data1.txt", "w");
    //     fid02 = $fopen("./sim_outdata/data2.txt", "w");
    //     fid03 = $fopen("./sim_outdata/data3.txt", "w");
    //     fid04 = $fopen("./sim_outdata/data4.txt", "w");
    //     fid05 = $fopen("./sim_outdata/data5.txt", "w");
    //     fid06 = $fopen("./sim_outdata/data6.txt", "w");
    //     fid07 = $fopen("./sim_outdata/data7.txt", "w");
    //     fid08 = $fopen("./sim_outdata/data8.txt", "w");
    // end
    // always @(negedge clk) begin
    //     $fwrite(fid01, "%d\n", $signed(xn_i));
    //     $fwrite(fid02, "%d\n", $signed(xn_q));
    //     $fwrite(fid03, "%d\n", $signed(L0_out0_i));
    //     $fwrite(fid04, "%d\n", $signed(L0_out0_q));
    //     $fwrite(fid05, "%d\n", $signed(NL_out0_i));
    //     $fwrite(fid06, "%d\n", $signed(NL_out0_q));
    //     $fwrite(fid07, "%d\n", $signed(L1_out_i));
    //     $fwrite(fid08, "%d\n", $signed(L1_out_q));
    // end
    // initial begin

    //     #(PERIOD * 3000 * 8) begin
    //         $fclose(fid01);
    //         $fclose(fid02);
    //         $fclose(fid03);
    //         $fclose(fid04);
    //         $fclose(fid05);
    //         $fclose(fid06);
    //         $fclose(fid07);
    //         $fclose(fid08);
    //         // $fclose(fid09);
    //         // $fclose(fid10);
    //         $stop;
    //     end
    // end

endmodule
