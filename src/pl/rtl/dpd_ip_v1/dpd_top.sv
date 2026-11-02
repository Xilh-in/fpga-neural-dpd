module dpd_top(
    input  wire                          clk                        ,
    input  wire                          rst_n                      ,
    input  wire                          dpd_coe_en                 ,
    input  wire                          dpd_coe_wr                 ,
    input  wire         [   9: 0]        dpd_coe_addr               ,
    input  wire         [  15: 0]        dpd_coe_wdata              ,// --- (16, 3)
    input  wire                          din_vd                     ,
    // input  wire signed   [15:0]  lr;                     // --- (1, 16, 15)
    input  wire signed  [  15: 0]        xn_i                       ,// --- (1, 16, 15)
    input  wire signed  [  15: 0]        xn_q                       ,// --- (1, 16, 15)
    output wire                          dout_vd                    ,
    output wire signed  [  15: 0]        yn_i                       ,// --- (1, 20, 15)
    output wire signed  [  15: 0]        yn_q                       ,// --- (1, 20, 15)
    output reg  signed  [  15: 0]        dpd_coe_rdata               // --- (16, 3)
    );

parameter                           filt_order                = 33    ;
parameter                           filt_delay                = (filt_order-1)/2;


 
// model out
wire                                L1_vd               [0:6]  ;
wire     signed    [  15: 0]        L1_out_i            [0:6]  ;
wire     signed    [  15: 0]        L1_out_q            [0:6]  ;
wire                                L2_vd               [0:6]  ;
wire     signed    [  15: 0]        L2_out_i            [0:6]  ;
wire     signed    [  15: 0]        L2_out_q            [0:6]  ;
wire                                L3_vd                      ;
wire     signed    [  15: 0]        L3_out_i                   ;
wire     signed    [  15: 0]        L3_out_q                   ;

// --- load parameter --- //
reg     signed     [  15: 0]        dpd_coe          [0: 575]  ;
wire               [576*16-1: 0]    expcnn_para                ;

genvar ii;
generate
    for (ii=0; ii<576; ii=ii+1) begin
        assign expcnn_para[ii*16+:16] = dpd_coe[ii];
    end
endgenerate


always @(posedge clk) begin :load_para
    integer ii;
    if(!rst_n) begin
        for (ii=0; ii<576; ii=ii+1) begin
            dpd_coe[ii] <= 'd0;
        end
    end
    else if(dpd_coe_en) begin
        if(dpd_coe_wr) begin
            dpd_coe[dpd_coe_addr] <= dpd_coe_wdata;
        end
        else begin
            dpd_coe_rdata <= dpd_coe[dpd_coe_addr];
        end
    end
end

// --- expcnn output --- //
assign dout_vd = L3_vd;
assign yn_i    = L3_out_i;
assign yn_q    = L3_out_q;

expcnn u_ExpCNN(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd                    ),
    .xn_i                               (xn_i                      ),
    .xn_q                               (xn_q                      ),
    .expcnn_para                        (expcnn_para               ),
// --- linear_layer_0 signal --- //
    .L1_vd                              (L1_vd                     ),
    .L1_out_i                           (L1_out_i                  ),
    .L1_out_q                           (L1_out_q                  ),
// --- nonlinear_layer signal --- //
    .L2_vd                              (L2_vd                     ),
    .L2_out_i                           (L2_out_i                  ),
    .L2_out_q                           (L2_out_q                  ),
// --- linear_layer_1 signal --- //
    .L3_vd                              (L3_vd                     ),
    .L3_out_i                           (L3_out_i                  ),
    .L3_out_q                           (L3_out_q                  )
);


// expcnn u_ExpCNN(
//     .clk                                (clk                       ),
//     .rst_n                              (rst_n                     ),
//     .en                                 (en                        ),
//     .din_vd                             (din_vd                    ),
//     .xn_i                               (xn_i                      ),
//     .xn_q                               (xn_q                      ),
//     .expcnn_para                        (expcnn_para               ),
//     .dout_vd                            (dout_vd                   ),
//     .yn_i                               (model_out_i               ),
//     .yn_q                               (model_out_q               ) 
// );





endmodule