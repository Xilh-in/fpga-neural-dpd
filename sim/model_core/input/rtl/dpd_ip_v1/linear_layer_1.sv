// -----------------------------------------------------------------------------
// --- linear_layer_1 module
// --- the third layer of EXPCNN
// --- Full Connected Layer
// --- input(1 channel) --> output(1 channel)
// -----------------------------------------------------------------------------
module linear_layer_1(
    input  wire                            clk                        ,
    input  wire                            rst_n                      ,
    input  wire                            din_vd    [0:6]            ,
    input  wire signed [  15: 0]           xn_i      [0:6]            ,// --- (16, 2)
    input  wire signed [  15: 0]           xn_q      [0:6]            ,// --- (16, 2)
    input  wire        [2*16-1:0]          filt_para [0:7]            ,// --- (16, 3)

    output wire                            L_out_vd                   ,
    output reg  signed [  15: 0]           L_out_i                    ,
    output reg  signed [  15: 0]           L_out_q                      
);

// --- L3 Layer signal
wire                                din_vd_comb                 ;
reg                                 din_vd_d1                   ;
reg                                 din_vd_d2                   ;
reg                                 din_vd_d3                   ;
reg                                 din_vd_d4                   ;
// wire    signed     [  32: 0]        multi_0      [0:6]          ;// -- (16, 3) * (16, 5) = (33, 9) iq
// wire    signed     [  32: 0]        multi_1      [0:6]          ;// -- (16, 3) * (16, 5) = (33, 9) iq
// wire    signed     [  32: 0]        multi_2      [0:6]          ;// -- (16, 3) * (16, 5) = (33, 9) iq
reg     signed     [  32: 0]        multi_0      [0:6]          ;// -- (16, 3) * (16, 2) = (33, 6) iq
reg     signed     [  32: 0]        multi_1      [0:6]          ;// -- (16, 3) * (16, 2) = (33, 6) iq
reg     signed     [  32: 0]        multi_2      [0:6]          ;// -- (16, 3) * (16, 2) = (33, 6) iq
reg     signed     [  32: 0]        prodt_out_i  [0:6]          ;// -- (16, 3) * (16, 2) = (33, 6) iq
reg     signed     [  32: 0]        prodt_out_q  [0:6]          ;// -- (16, 3) * (16, 2) = (33, 6) iq
reg     signed     [  33: 0]        adder_s0_i   [0:3]          ;// -- (34, 7)
reg     signed     [  33: 0]        adder_s0_q   [0:3]          ;// -- (34, 7)
reg     signed     [  34: 0]        adder_s1_i   [0:1]          ;// -- (35, 8)
reg     signed     [  34: 0]        adder_s1_q   [0:1]          ;// -- (35, 8)
reg     signed     [  35: 0]        yout_i                      ;// -- (36, 9)
reg     signed     [  35: 0]        yout_q                      ;// -- (36, 9)
reg     signed     [  36: 0]        L_out_i_L                   ;// -- (37, 10)
reg     signed     [  36: 0]        L_out_q_L                   ;// -- (37, 10)

// --- filt_para_wire signal --- //
wire    signed     [  15: 0]        filt_para_i[0:7]            ;// --- (16, 3)
wire    signed     [  15: 0]        filt_para_q[0:7]            ;// --- (16, 3)

// --- load filt_para --- //
genvar ii;
generate
    for (ii=0; ii<8; ii=ii+1) begin
        assign filt_para_i[ii] = filt_para[ii][15: 0];
        assign filt_para_q[ii] = filt_para[ii][31:16];
    end
endgenerate

// --- generate out_vd signal (delay 2T)--- //
assign din_vd_comb = din_vd[6]&din_vd[5]&din_vd[4]&din_vd[3]&din_vd[2]&din_vd[1]&din_vd[0];

always @(posedge clk) begin
    if(!rst_n) begin
        din_vd_d1 <= 1'b0;
        din_vd_d2 <= 1'b0;
        din_vd_d3 <= 1'b0;
        din_vd_d4 <= 1'b0;
    end
    else begin
        din_vd_d1 <= din_vd_comb;
        din_vd_d2 <= din_vd_d1;
        din_vd_d3 <= din_vd_d2;
        din_vd_d4 <= din_vd_d3;
    end
end


always @(posedge clk ) begin:multiply_0 
    integer ii;
    for(ii = 0; ii < 7; ii = ii + 1) begin
        if(!rst_n) begin
            multi_0[ii] <= 'd0;
            multi_1[ii] <= 'd0;
            multi_2[ii] <= 'd0;
        end
        else if(din_vd_comb) begin
            multi_0[ii] <= xn_i[ii] *  (filt_para_i[ii] - filt_para_q[ii]);
            multi_1[ii] <= xn_q[ii] *  (filt_para_i[ii] + filt_para_q[ii]);
            multi_2[ii] <= filt_para_q[ii] * (xn_i[ii] - xn_q[ii]);
        end
    end
    
end


// generate
//     for(ii = 0; ii < 7; ii = ii + 1) begin
//         assign multi_0[ii] = xn_i[ii] *  (filt_para_i[ii] - filt_para_q[ii]);
//         assign multi_1[ii] = xn_q[ii] *  (filt_para_i[ii] + filt_para_q[ii]);
//         assign multi_2[ii] = filt_para_q[ii] * (xn_i[ii] - xn_q[ii]);
//     end
// endgenerate
// generate
//     for(ii = 0; ii < 7; ii = ii + 1) begin
//         assign multi_0[ii] = xn_i[ii] * $signed({filt_para_i[ii][15], filt_para_i[ii]} - {filt_para_q[ii][15], filt_para_q[ii]});
//         assign multi_1[ii] = xn_q[ii] * $signed({filt_para_i[ii][15], filt_para_i[ii]} + {filt_para_q[ii][15], filt_para_q[ii]});
//         assign multi_2[ii] = filt_para_q[ii] * $signed({xn_i[ii][15], xn_i[ii]} - {xn_q[ii][15], xn_q[ii]});
//     end
// endgenerate

always @(posedge clk) begin:multiply_1 
    integer ii;
    for(ii=0; ii<7; ii=ii+1) begin
        if(!rst_n) begin
            prodt_out_i[ii] <= 'd0;
            prodt_out_q[ii] <= 'd0;
        end
        else begin
            if(din_vd_d1)begin
                prodt_out_i[ii] <= multi_0[ii] + multi_2[ii];  // -- (16, 3) * (16, 5) = (33, 9) iq
                prodt_out_q[ii] <= multi_1[ii] + multi_2[ii];  // -- (16, 3) * (16, 5) = (33, 9) iq
            end
        end     
    end
end

// --- adder (delay 2T)--- //
always @(*) begin
    integer ii;

    adder_s0_i[3] = prodt_out_i[6];
    adder_s0_q[3] = prodt_out_q[6];
    for (ii=0; ii<3; ii=ii+1) begin
        adder_s0_i[ii] = prodt_out_i[2*ii] + prodt_out_i[2*ii+1];
        adder_s0_q[ii] = prodt_out_q[2*ii] + prodt_out_q[2*ii+1];
    end

    yout_i = adder_s1_i[1] + adder_s1_i[0];
    yout_q = adder_s1_q[1] + adder_s1_q[0];
end

always @(posedge clk) begin :adder
    integer ii;
    if(!rst_n) begin
        for (ii=0; ii<2; ii=ii+1) begin
            adder_s1_i[ii] <= 'd0;
            adder_s1_q[ii] <= 'd0;
        end

        L_out_i_L <= 'd0;
        L_out_q_L <= 'd0;
    end
    else begin
        if(din_vd_d2) begin
            for (ii=0; ii<2; ii=ii+1) begin
                adder_s1_i[ii] <= adder_s0_i[2*ii] + adder_s0_i[2*ii+1];
                adder_s1_q[ii] <= adder_s0_q[2*ii] + adder_s0_q[2*ii+1];
            end
        end

        if(din_vd_d3) begin
            L_out_i_L <= yout_i + $signed({{6{filt_para_i[7][15]}}, filt_para_i[7], 14'd0});  // -- (36, 9) + (36, 9) = (37, 10)
            L_out_q_L <= yout_q + $signed({{6{filt_para_q[7][15]}}, filt_para_q[7], 14'd0});  // -- (36, 9) + (36, 9) = (37, 10)
        end
        else begin
            L_out_i_L <= 'd0;
            L_out_q_L <= 'd0;
        end
    end
end

// -- generate output signal
assign L_out_vd = din_vd_d4;

// data saturation (37, 10) -> (16, 1)
always @(*) begin
    if(L_out_i_L[36]) begin
        if(L_out_i_L[35:27] == 9'h1ff)begin
            L_out_i = L_out_i_L[27-:16];
        end
        else begin
            L_out_i = {1'b1, {15{1'b0}}};
        end
    end
    else begin
        if(L_out_i_L[35:27] == 9'h000)begin
            L_out_i = L_out_i_L[27-:16];
        end
        else begin
            L_out_i = {1'b0, {15{1'b1}}};
        end
    end

    if(L_out_q_L[36]) begin
        if(L_out_q_L[35:27] == 9'h1ff)begin
            L_out_q = L_out_q_L[27-:16];
        end
        else begin
            L_out_q = {1'b1, {15{1'b0}}};
        end
    end
    else begin
        if(L_out_q_L[35:27] == 9'h000)begin
            L_out_q = L_out_q_L[27-:16];
        end
        else begin
            L_out_q = {1'b0, {15{1'b1}}};
        end
    end
end

endmodule