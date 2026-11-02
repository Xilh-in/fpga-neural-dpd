// -----------------------------------------------------------------------------
// --- nonlinear_layer module (delay 37T)
// --- the NL layer of EXPCNN
// --- NL_func: exp[(abs(signal)-centers)**2 * theta]
// --- signal(1 channel)    centers_num:1*12    theta:1*12
// --- NL_output:1 channel
// -----------------------------------------------------------------------------
module nl_core(
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,
    input  wire                         din_vd                     ,
    input  wire signed [  15: 0]        NL_input_i                 ,// --- (16, 3)
    input  wire signed [  15: 0]        NL_input_q                 ,// --- (16, 3)
    input  wire signed [9*4*16-1: 0]    NL_para                    ,// --- (16, 3)

    output wire                         NL_out_vd                  , 
    output reg  signed [  15: 0]        NL_out_i                   ,// --- (16, 5)
    output reg  signed [  15: 0]        NL_out_q                    // --- (16, 5)
         
    // output wire signed [20*12-1:0]   grad_1_out      ,      // (34, 7) --> (20, 7)
    // output wire signed [20*12-1:0]   grad_0_i_out    ,      // (33, 6) --> (20, 5)
    // output wire signed [20*12-1:0]   grad_0_q_out    ,      // (33, 6) --> (20, 5)
    // output wire signed [20*12-1:0]   f2_out          ,      // (36, 8) --> (20, 7)
    // output wire signed [20*12-1:0]   f0_out          ,    
    // output wire signed [19:0]        grad_2_i_out    ,      // (36, 8) --> (20, 5)
    // output wire signed [19:0]        grad_2_q_out    ,      // (36, 8) --> (20, 5)
);

parameter FUNC_NUM = 9;

// --- NL para --- //
wire signed [15:0] centers            [0:FUNC_NUM-1];     // --- (16, 3)
wire signed [15:0] theta              [0:FUNC_NUM-1];     // --- (16, 4)
wire signed [15:0] weights_i          [0:FUNC_NUM-1];     // --- (16, 3)
wire signed [15:0] weights_q          [0:FUNC_NUM-1];     // --- (16, 3)

// --- define generate variable --- //
genvar cnt;
genvar ii;

// --- abs signal --- //
wire               abs_out_vd;
wire               abs_dout_vd_0;
wire signed [16:0] abs_out;                           // --- (17, 4)

reg                abs_out_vd_d0;
reg                abs_out_vd_d1;
reg                abs_out_vd_d2;

// --- NL_func signal --- //
// wire define
wire  signed [24:0]   exp_output       [0:FUNC_NUM-1];        // --- (25, 7)
wire  signed [32:0]   grad_0_q_L_neg   [0:FUNC_NUM-1];        // --- (16, 3) * (16, 3) -> (33, 7)
  
// reg define
reg   signed [17:0] distance           [0:FUNC_NUM-1];        // --- (18, 5)
reg   signed [35:0] signal_sqr_L       [0:FUNC_NUM-1];        // --- (36, 8)
reg   signed [24:0] signal_sqr         [0:FUNC_NUM-1];        // --- (25, 6)
reg   signed [40:0] exp_input_L        [0:FUNC_NUM-1];        // --- (41,10)
reg   signed [24:0] exp_input          [0:FUNC_NUM-1];        // --- (25, 7)
reg   signed [24:0] exp_input_d        [0:FUNC_NUM-1];        // --- (25, 7)
reg   signed [24:0] exp_output_d       [0:FUNC_NUM-1];        // --- (25, 7)
reg   signed [49:0] prodt_out_L_i      [0:FUNC_NUM-1];        // --- weights_i * exp_output => (25, 7)*(25, 4) = (50, 11)
reg   signed [49:0] prodt_out_L_q      [0:FUNC_NUM-1];        // --- weights_q * exp_output => (25, 7)*(25, 4) = (50, 11)
reg   signed [24:0] prodt_out_i        [0:FUNC_NUM-1];        // --- (50, 11) -> (25, 2)
reg   signed [24:0] prodt_out_q        [0:FUNC_NUM-1];        // --- (50, 11) -> (25, 2)

reg   signed [25:0] adder_s0_i         [0:4];        // --- (26, 3)
reg   signed [25:0] adder_s0_q         [0:4];        // --- (26, 3)
reg   signed [26:0] adder_s1_i         [0:1];        // --- (27, 4)
reg   signed [26:0] adder_s1_q         [0:1];        // --- (27, 4)
reg   signed [27:0] adder_s2_i         [0:1];        // --- (28, 5)
reg   signed [27:0] adder_s2_q         [0:1];        // --- (28, 5)
reg   signed [28:0] y_out_i                 ;        // --- (29, 6)
reg   signed [28:0] y_out_q                 ;        // --- (29, 6)
 
reg   signed [15:0] NL_input_i_r      [0:36];        // --- (16, 3)
reg   signed [15:0] NL_input_q_r      [0:36];        // --- (16, 3)

// reg   signed [33:0] grad_1_L          [0:11];        // (18, 5) * (16, 3) --> (34, 8)
reg   signed [31:0] grad_0_i_L        [0:FUNC_NUM-1];        // (16, 3) * (16, 3) --> (32, 6)
reg   signed [31:0] grad_0_q_L        [0:FUNC_NUM-1];        // (16, 3) * (16, 3) --> (32, 6)
// reg   signed [35:0] grad_2_i_L        [0:11];        // (16, 3) * (20, 5) --> (36, 8)
// reg   signed [35:0] grad_2_q_L        [0:11];        // (16, 3) * (20, 5) --> (36, 8)
// reg   signed [36:0] adder0_grad2_i    [0: 5];        // (37, 9)
// reg   signed [36:0] adder0_grad2_q    [0: 5];        // (37, 9)
// reg   signed [37:0] adder1_grad2_i    [0: 2];        // (38, 10)
// reg   signed [37:0] adder1_grad2_q    [0: 2];        // (38, 10)
// reg   signed [38:0] adder2_grad2_i    [0: 1];        // (39, 11)
// reg   signed [38:0] adder2_grad2_q    [0: 1];        // (39, 11)
// reg   signed [39:0] sum_grad2_i             ;        // (40, 12)
// reg   signed [39:0] sum_grad2_q             ;        // (40, 12)
// reg   signed [19:0] grad2_i                 ;        // (40, 12) --> (20, 5)
// reg   signed [19:0] grad2_q                 ;        // (40, 12) --> (20, 5)

reg                 exp_dout_vd       ;
reg                 exp_dout_vd_d0    ;
reg                 exp_dout_vd_d1    ;
reg                 exp_dout_vd_d2    ;
wire [FUNC_NUM-1:0] exp_dout_vd_array ;


// coe data signal //
// reg   signed [20-1:0] grad_1           [0:11];        // (34, 8) --> (20, 7)
reg   signed [25-1:0] grad_0_i         [0:FUNC_NUM-1];        // (32, 6) --> (25, 4)
reg   signed [25-1:0] grad_0_q         [0:FUNC_NUM-1];        // (32, 6) --> (25, 4)
// reg   signed [20-1:0] grad_0_q_neg     [0:11];        // (33, 7) --> (20, 5)
// wire  signed [20-1:0] f2               [0:11];        // (36, 8) --> (20, 7)
// wire  signed [20-1:0] f0               [0:11];  

// --- load NL parameters --- //
generate
    for (ii = 0; ii < 9; ii = ii + 1) begin : Load_NL_para
        assign centers[ii]   = NL_para[(ii*16)      +:16];
        assign theta[ii]     = NL_para[((ii+9)*16)  +:16];
        assign weights_i[ii] = NL_para[((ii+9*2)*16)+:16];
        assign weights_q[ii] = NL_para[((ii+9*3)*16)+:16];
    end
endgenerate

// --- get phase information (din_shift_reg) --- //
always @(posedge clk) begin :input_shift_reg
    integer cnt;
    if(!rst_n) begin
        for (cnt = 0; cnt < 37; cnt = cnt + 1) begin
            NL_input_i_r[cnt] <= 'd0;
            NL_input_q_r[cnt] <= 'd0;
        end
    end else begin
        NL_input_i_r[0] <= NL_input_i;
        NL_input_q_r[0] <= NL_input_q;
        for (cnt = 1; cnt < 37; cnt = cnt + 1) begin
            NL_input_i_r[cnt] <= NL_input_i_r[cnt-1];
            NL_input_q_r[cnt] <= NL_input_q_r[cnt-1];
        end
    end    
end

// --- compute iq signal abs (delay 9T)--- //
assign abs_out_vd = abs_dout_vd_0 ;

always @(posedge clk) begin
    if(!rst_n) begin
        abs_out_vd_d0 <= 1'b0;
        abs_out_vd_d1 <= 1'b0;
        abs_out_vd_d2 <= 1'b0;
    end else begin
        abs_out_vd_d0 <= abs_out_vd;
        abs_out_vd_d1 <= abs_out_vd_d0;
        abs_out_vd_d2 <= abs_out_vd_d1;
    end
end

cordic_abs # (
    .DW(16),
    .NW(3),
    .EPC(9)
    )
    u_cordic_abs_0(
    .clk         (clk           ),
    .rst_n       (rst_n         ),
    .din_vd      (din_vd        ),
    .din_x       (NL_input_i    ),
    .din_y       (NL_input_q    ),
    .abs_dout_vd (abs_dout_vd_0 ),
    .abs_out     (abs_out       )
);

// ---------------------------------------------------------------
// --- NL_func: exp[(abs(signal)-centers)**2 * theta] 
// --- signal(3 channels)    centers_num:3*16    theta:3*16
// ---------------------------------------------------------------
// --- compute abs(signal)-centers --- //
always @(*) begin :signal_minus_center
    integer cnt;

    for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
        distance[cnt] = 'd0;

        if (rst_n && abs_out_vd) begin
            distance[cnt] =
                abs_out - $signed({centers[cnt][15], centers[cnt]});
        end
    end
end

// --- compute x**2  (delay 1T) --- //
always @(posedge clk) begin : compute_signal_sqr_L
    integer cnt;
    if(!rst_n)begin
        for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
            signal_sqr_L [cnt] <= 'd0;
        end
    end else if(abs_out_vd) begin
        for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
            signal_sqr_L [cnt] <= distance[cnt] * distance[cnt];  // (18, 5)*(18, 5) --> (36, 10)
        end
    end
end

// -- signal_sqr_saturation (36, 10) -> (25, 6)
always @(*) begin :signal_sqr_saturation
    integer cnt;
    for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
        if(signal_sqr_L[cnt][35]) begin
            if(signal_sqr_L[cnt][34:31] == 4'hf) begin
                signal_sqr[cnt] = signal_sqr_L[cnt][31-:25];  // (36, 10) --> (25, 6)
            end
            else begin
                signal_sqr[cnt] = {1'b1, {24{1'b0}}};
            end
        end
        else begin
            if(signal_sqr_L[cnt][34:31] == 4'h0) begin
                signal_sqr[cnt] = signal_sqr_L[cnt][31-:25];  // (36, 10) --> (25, 6)
            end
            else begin
                signal_sqr[cnt] = {1'b0, {24{1'b1}}};
            end
        end
    end
end

// --- compute -x**2 * theta (delay 1T)--- //
always @(posedge clk) begin : exp_input_L_signal
    integer cnt;
    if(!rst_n) begin
        for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
            exp_input_L[cnt] <= 'd0;
        end
    end else if(abs_out_vd_d0) begin
        for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
            exp_input_L[cnt] <= theta[cnt][15]? signal_sqr[cnt] * theta[cnt] : -signal_sqr[cnt] * theta[cnt];  // (25, 6) * (16, 4) --> (41, 10)
        end
    end
end

// generate
//     for (cnt = 0; cnt < 12; cnt = cnt + 1) begin :exp_input_ops
//         assign exp_input_L_ops[cnt] = (exp_input_L[cnt]=='d0)? 'd0: ((exp_input_L[cnt][35])? {1'b0, ~exp_input_L[cnt][34:0] + 1'b1}:{1'b1, ~exp_input_L[cnt][34:0] + 1'b1});
//     end
// endgenerate
// --- data saturation  (41, 10) -> (25, 7)  
generate
    for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin :exp_input_signal
        always @(*) begin
            if (exp_input_L[cnt][40]) begin
                if (exp_input_L[cnt][39:37] == 3'b111) begin
                    exp_input[cnt] = exp_input_L[cnt][37-:25];
                end else begin
                    exp_input[cnt] = {1'b1,{24{1'b0}}};
                end
            end 
            else begin
                if (exp_input_L[cnt][39:37] == 3'b000) begin
                    exp_input[cnt] = exp_input_L[cnt][37-:25];
                end else begin
                    exp_input[cnt] = {1'b0,{24{1'b1}}};
                end
            end
        end
    end
endgenerate

// --- delay 1T --- //
always @(posedge clk) begin :exp_input_shorten
    integer ii;
    if(!rst_n) begin
        for (ii = 0; ii < FUNC_NUM; ii = ii + 1) begin
            exp_input_d[ii] <= 'd0;
        end
    end else if(abs_out_vd_d1)begin
        for (ii = 0; ii < FUNC_NUM; ii = ii + 1) begin
            exp_input_d[ii] <= exp_input[ii];
        end
    end
end

// --- exp_out = exp(-x**2 * theta) (delay 20T)--- //
// assign exp_dout_vd = exp_dout_vd_array[0];
always @(posedge clk) begin
    if(!rst_n) 
        exp_dout_vd <= 1'b0;
    else
        exp_dout_vd <= &exp_dout_vd_array;
end

always @(posedge clk) begin
    if(!rst_n) begin
        exp_dout_vd_d0 <= 1'b0;
        exp_dout_vd_d1 <= 1'b0;
        exp_dout_vd_d2 <= 1'b0;
    end else begin
        exp_dout_vd_d0 <= exp_dout_vd;
        exp_dout_vd_d1 <= exp_dout_vd_d0;
        exp_dout_vd_d2 <= exp_dout_vd_d1;
    end
end


generate
    for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin :get_exp_out
        cordic_exp # (
        .DW(25),
        .NW(7)
        ) u_cordic_exp(
            .clk               (clk                    ),
            .rst_n             (rst_n                  ),
            .din_vd            (abs_out_vd_d2          ),
            .din               (exp_input_d[cnt]       ),
            .exp_dout_vd       (exp_dout_vd_array[cnt] ),
            .exp_out           (exp_output[cnt]        )
        );
    end
endgenerate

// -- exp_out delay 1T
always @(posedge clk) begin :exp_out_delay_1T
    integer ii;
    if(!rst_n) begin
        for(ii = 0; ii < FUNC_NUM; ii = ii + 1) begin
            exp_output_d[ii] <= 'd0;
        end
    end
    else if(&exp_dout_vd_array) begin
        for(ii = 0; ii < FUNC_NUM; ii = ii + 1) begin
            exp_output_d[ii] <= exp_output[ii];
        end
    end
end

// --- exp_output * (weights_i, weights_q) = prodt_out_i, prodt_out_q (delay 1T) --- //
always @(posedge clk) begin :get_prodt_out
    integer cnt;
    if(!rst_n) begin
        for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
            prodt_out_L_i[cnt] <= 'd0;
            prodt_out_L_q[cnt] <= 'd0;
        end
    end else begin
        if(exp_dout_vd) begin
            for (cnt = 0; cnt < FUNC_NUM; cnt = cnt + 1) begin
                prodt_out_L_i[cnt] <= exp_output_d[cnt] * grad_0_i[cnt];  // ---(25, 7)*(25, 4) = (50, 11)
                prodt_out_L_q[cnt] <= exp_output_d[cnt] * grad_0_q[cnt];  // ---(25, 7)*(25, 4) = (50, 11)
            end
        end 
    end
end

generate
    for(ii = 0; ii < FUNC_NUM; ii = ii + 1) begin : prodt_out_L_fixpoint
        // data saturation (50, 11) -> (25, 2)
        always @(*) begin
            if (prodt_out_L_i[ii][49]) begin
                if (prodt_out_L_i[ii][48:40] == 9'h1ff) begin
                    prodt_out_i[ii] = prodt_out_L_i[ii][40-:25];
                end else begin
                    prodt_out_i[ii] = {1'b1,{24{1'b0}}};
                end
            end else begin
                if (prodt_out_L_i[ii][48:40] == 9'h000) begin
                    prodt_out_i[ii] = prodt_out_L_i[ii][40-:25];
                end else begin
                    prodt_out_i[ii] = {1'b0,{24{1'b1}}};
                end
            end
        end
        always @(*) begin
            if (prodt_out_L_q[ii][49]) begin
                if (prodt_out_L_q[ii][48:40] == 9'h1ff) begin
                    prodt_out_q[ii] = prodt_out_L_q[ii][40-:25];
                end else begin
                    prodt_out_q[ii] = {1'b1,{24{1'b0}}};
                end
            end else begin
                if (prodt_out_L_q[ii][48:40] == 9'h000) begin
                    prodt_out_q[ii] = prodt_out_L_q[ii][40-:25];
                end else begin
                    prodt_out_q[ii] = {1'b0,{24{1'b1}}};
                end
            end
        end
    end
endgenerate

// -- adder delay 2T--//
always @(*) begin :addition
    integer ii;

    for(ii=0; ii<2; ii=ii+1) begin
        adder_s1_i[ii] = adder_s0_i[2*ii] + adder_s0_i[2*ii+1]; 
        adder_s1_q[ii] = adder_s0_q[2*ii] + adder_s0_q[2*ii+1]; 
    end

    adder_s2_i[0] = adder_s1_i[0] + adder_s1_i[1]; 
    adder_s2_q[0] = adder_s1_q[0] + adder_s1_q[1]; 
    adder_s2_i[1] = adder_s0_i[4]; 
    adder_s2_q[1] = adder_s0_q[4]; 

end

always @(posedge clk) begin:adder
    integer ii;
    if(!rst_n) begin
        for(ii = 0; ii < 6; ii = ii + 1) begin
            adder_s0_i[ii] <= 0;
            adder_s0_q[ii] <= 0;
        end
            y_out_i <= 0;
            y_out_q <= 0;
    end else begin
        if(exp_dout_vd_d0)begin
            adder_s0_i[4] <= prodt_out_i[FUNC_NUM-1];
            adder_s0_q[4] <= prodt_out_q[FUNC_NUM-1];
            for(ii = 0; ii < 4; ii = ii + 1) begin
                adder_s0_i[ii] <= prodt_out_i[2*ii] + prodt_out_i[2*ii+1];
                adder_s0_q[ii] <= prodt_out_q[2*ii] + prodt_out_q[2*ii+1];
            end
        end
        
        if(exp_dout_vd_d1) begin
                y_out_i <= adder_s2_i[0] + adder_s2_i[1];
                y_out_q <= adder_s2_q[0] + adder_s2_q[1];
        end
    end    
end


// --- generate output --- //
// --- NL_out_r = prodt_out_r * input_r - prodt_out_i * input_i --- //  
// --- NL_out_i = prodt_out_r * input_i + prodt_out_i * input_r --- //  
assign NL_out_vd = exp_dout_vd_d2;

// output (29, 6) --> (16, 2)
always @(*) begin
    if(NL_out_vd) begin
        if (y_out_i[28]) begin
            if (y_out_i[27:24] == 4'b1111) begin
                NL_out_i = y_out_i[24-:16];
            end else begin
                NL_out_i = {1'b1,{15{1'b0}}};
            end
        end else begin
            if (y_out_i[27:24] == 4'b0000) begin
                NL_out_i = y_out_i[24-:16];
            end else begin
                NL_out_i = {1'b0,{15{1'b1}}};
            end
        end
        if (y_out_q[28]) begin
            if (y_out_q[27:24] == 4'b1111) begin
                NL_out_q = y_out_q[24-:16];
            end else begin
                NL_out_q = {1'b1,{15{1'b0}}};
            end
        end else begin
            if (y_out_q[27:24] == 4'b0000) begin
                NL_out_q = y_out_q[24-:16];
            end else begin
                NL_out_q = {1'b0,{15{1'b1}}};
            end
        end
    end
    else begin
        NL_out_i = 16'd0;
        NL_out_q = 16'd0;
    end
    
end
////////////////////////////////////////////////////////////////////////////
//coe data calculation
////////////////////////////////////////////////////////////////////////////


// --- (delay 1T) --- //
// always @(posedge clk) begin : grad1
//     integer ii;
//     for (ii = 0; ii < 12; ii = ii + 1) begin
//         if(!rst_n) begin
//             grad_1_L[ii]    <=  0;
//         end else if(abs_out_vd) begin
//             grad_1_L[ii]    <=  -distance[ii] * theta[ii];   // (18, 5) * (16, 3) --> (34, 8)
//         end
//     end
// end

always @(posedge clk) begin : grad0
    integer ii;
    for (ii = 0; ii < FUNC_NUM; ii = ii + 1) begin
        if(!rst_n) begin
            grad_0_i_L[ii] <= 0;  
            grad_0_q_L[ii] <= 0;  
        end else if(&exp_dout_vd_array) begin
            grad_0_i_L[ii] <= NL_input_i_r[36-ii] * weights_i[ii];  // --- (16, 3) *  (16, 3) --> (32, 6)
            grad_0_q_L[ii] <= NL_input_q_r[36-ii] * weights_q[ii];  // --- (16, 3) *  (16, 3) --> (32, 6)
        end
    end
end
// generate
//     for (ii = 0; ii < 12; ii = ii + 1) begin
//         assign grad_0_q_L_neg[ii] = -grad_0_q_L[ii];
//     end
// endgenerate


// // -- get grad2
// always @(posedge clk) begin : grad2
//     integer ii;
//     for (ii = 0; ii < 12; ii = ii + 1) begin
//         if(!rst_n) begin
//             grad_2_i_L[ii] <= 0;  
//             grad_2_q_L[ii] <= 0;  
//         end else if(exp_dout_vd) begin
//             grad_2_i_L[ii] <=  weights_i[ii] * exp_output_d[ii];  // --- (16, 3) * (20, 5) --> (36, 8)
//             grad_2_q_L[ii] <= -weights_q[ii] * exp_output_d[ii];  // --- (16, 3) * (20, 5) --> (36, 8)
//         end
//     end
// end



// // -- adder delay 2T--//
// always @(*) begin :addition_grad2
//     integer ii;
//     for(ii=0; ii<3; ii=ii+1) begin
//         adder1_grad2_i[ii] = adder0_grad2_i[2*ii] + adder0_grad2_i[2*ii+1]; 
//         adder1_grad2_q[ii] = adder0_grad2_q[2*ii] + adder0_grad2_q[2*ii+1]; 
//     end

//     adder2_grad2_i[0] = adder1_grad2_i[0] + adder1_grad2_i[1]; 
//     adder2_grad2_q[0] = adder1_grad2_q[0] + adder1_grad2_q[1]; 
//     adder2_grad2_i[1] = adder1_grad2_i[2]; 
//     adder2_grad2_q[1] = adder1_grad2_q[2]; 
// end

// always @(posedge clk) begin:adder_grad2
//     integer ii;
//     if(!rst_n) begin
//         for(ii = 0; ii < 6; ii = ii + 1) begin
//             adder0_grad2_i[ii] <= 0;
//             adder0_grad2_q[ii] <= 0;
//         end
//         sum_grad2_i <= 0;
//         sum_grad2_q <= 0;
//     end else begin
//         if(exp_dout_vd_d0)begin
//             for(ii = 0; ii < 6; ii = ii + 1) begin
//                 adder0_grad2_i[ii] <= grad_2_i_L[2*ii] + grad_2_i_L[2*ii+1];
//                 adder0_grad2_q[ii] <= grad_2_q_L[2*ii] + grad_2_q_L[2*ii+1];
//             end
//         end
//         if(exp_dout_vd_d1) begin
//             sum_grad2_i <= adder2_grad2_i[0] + adder2_grad2_i[1];
//             sum_grad2_q <= adder2_grad2_q[0] + adder2_grad2_q[1];
//         end
//     end    
// end

// // data saturation (40, 12) -> (20, 5)
// always @(*) begin
//     if (sum_grad2_i[39]) begin
//         if (sum_grad2_i[38:32] == 7'h7f) begin
//             grad2_i = sum_grad2_i[32-:20];
//         end else begin
//             grad2_i = {1'b1,{15{1'b0}}};
//         end
//     end else begin
//         if (sum_grad2_i[38:32] == 7'h00) begin
//             grad2_i = sum_grad2_i[32-:20];
//         end else begin
//             grad2_i = {1'b0,{15{1'b1}}};
//         end
//     end

//     if (sum_grad2_q[39]) begin
//         if (sum_grad2_q[38:32] == 7'h7f) begin
//             grad2_q = sum_grad2_q[32-:20];
//         end else begin
//             grad2_q = {1'b1,{15{1'b0}}};
//         end
//     end else begin
//         if (sum_grad2_q[38:32] == 7'h00) begin
//             grad2_q = sum_grad2_q[32-:20];
//         end else begin
//             grad2_q = {1'b0,{15{1'b1}}};
//         end
//     end
// end


// -- get coe data 
always @(*) begin:cut_and_combine_t
    integer ii;
    for (ii = 0; ii < FUNC_NUM; ii = ii + 1) begin 
//         // -- grad_1 data_saturation (34, 8) --> (20, 7)
//         if(grad_1_L[ii][33]) begin
//             if(grad_1_L[ii][32] == 1'b1) begin
//                 grad_1[ii] = grad_1_L[ii][32-:20];
//             end
//             else begin
//                 grad_1[ii] = {1'b1, {19{1'b0}}};
//             end
//         end
//         else begin
//             if(grad_1_L[ii][32] == 1'b0) begin
//                 grad_1[ii] = grad_1_L[ii][32-:20];
//             end
//             else begin
//                 grad_1[ii] = {1'b0, {19{1'b1}}};
//             end
//         end

        // -- grad_0_i data_saturation (32, 6) --> (25, 4)
        if(grad_0_i_L[ii][31]) begin
            if(grad_0_i_L[ii][30:29] == 2'b11) begin
                grad_0_i[ii] = grad_0_i_L[ii][29-:25];
            end
            else begin
                grad_0_i[ii] = {1'b1, {24{1'b0}}};
            end
        end
        else begin
            if(grad_0_i_L[ii][30:29] == 2'b00) begin
                grad_0_i[ii] = grad_0_i_L[ii][29-:25];
            end
            else begin
                grad_0_i[ii] = {1'b0, {24{1'b1}}};
            end
        end

        // -- grad_0_q data_saturation (32, 6) --> (25, 4)
        if(grad_0_q_L[ii][31]) begin
            if(grad_0_q_L[ii][30:29] == 2'b11) begin
                grad_0_q[ii] = grad_0_q_L[ii][29-:25];
            end
            else begin
                grad_0_q[ii] = {1'b1, {24{1'b0}}};
            end
        end
        else begin
            if(grad_0_q_L[ii][30:29] == 2'b00) begin
                grad_0_q[ii] = grad_0_q_L[ii][29-:25];
            end
            else begin
                grad_0_q[ii] = {1'b0, {24{1'b1}}};
            end
        end

//         // -- grad_0_q_L_neg data_saturation (33, 7) --> (20, 5)
//         if(grad_0_q_L_neg[ii][32]) begin
//             if(grad_0_q_L_neg[ii][31:30] == 2'b11) begin
//                 grad_0_q_neg[ii] = grad_0_q_L_neg[ii][30-:20];
//             end
//             else begin
//                 grad_0_q_neg[ii] = {1'b1, {19{1'b0}}};
//             end
//         end
//         else begin
//             if(grad_0_q_L_neg[ii][31:30] == 2'b00) begin
//                 grad_0_q_neg[ii] = grad_0_q_L_neg[ii][30-:20];
//             end
//             else begin
//                 grad_0_q_neg[ii] = {1'b0, {19{1'b1}}};
//             end
//         end
    end
end

// generate
//     for (ii = 0; ii < 12; ii = ii + 1) begin
//         assign f2[ii]           = signal_sqr[ii];                                        // (36,10) --> (20, 7)
//         assign f0[ii]           = exp_output[ii];
//     end
// endgenerate

// generate
//     for (ii = 0; ii < 12; ii = ii + 1) begin :cut_and_combine
//         assign grad_1_out[20*ii+19:20*ii]   = grad_1[ii];                             // (34, 7) --> (20, 7)
//         assign f2_out[20*ii+19:20*ii]       = f2[ii];                                 // (36, 8) --> (20, 7)
//         assign f0_out[20*ii+19:20*ii]       = f0[ii];
//         assign grad_0_i_out[20*ii+19:20*ii] = grad_0_i[ii];                           // (33, 6) --> (20, 5)
//         assign grad_0_q_out[20*ii+19:20*ii] = grad_0_q_neg[ii];                       // (33, 6) --> (20, 5)
//     end
// endgenerate

// assign grad_2_i_out = grad2_i;  
// assign grad_2_q_out = grad2_q;  

endmodule