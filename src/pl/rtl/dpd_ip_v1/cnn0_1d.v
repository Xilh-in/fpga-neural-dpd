// -----------------------------------------------------------------------------
// CNN_1d taps：21
// CNN_1d dialation:2
// CNN_1d delay：(21 + 20 -1)/2 = 20
// CNN_1d computation delay：4
// CNN_1d total delay：delay = 20 + 4 = 24T 
// -----------------------------------------------------------------------------

module cnn0_1d(
    //input
    clk,
    rst_n,
    din_vd,
    xn_i,
    xn_q,
    filt_para_i_L,
    filt_para_q_L,
    //output
    dout_vd,
    yn_i,
    yn_q
);

input  wire                      clk            ;
input  wire                      rst_n          ;
input  wire                      din_vd         ;
input  wire signed [15:0]        xn_i           ;         // --- (16, 1)
input  wire signed [15:0]        xn_q           ;         // --- (16, 1)
input  wire signed [16*22-1:0]   filt_para_i_L  ;         // --- (16, 3)
input  wire signed [16*22-1:0]   filt_para_q_L  ;         // --- (16, 3)



output reg                dout_vd;
output reg signed [15:0]  yn_i;
output reg signed [15:0]  yn_q;

// define parameter 
parameter WIDTH_IN  = 39;
parameter WIDTH_ref = 31;
parameter WIDTH_OUT = 16;


// --- filt_para --- //
wire signed [15:0]  filt_bias_i            ;       // --- (16, 3)
wire signed [15:0]  filt_bias_q            ;       // --- (16, 3)
wire signed [15:0]  filt_para_i      [0:20];       // --- (16, 3)
wire signed [15:0]  filt_para_q      [0:20];       // --- (16, 3)


//--- cnn0_1d signal ---//
// define wire
wire               din_vd_d0              ;
wire signed [32:0] multi_0          [0:20];        // --- (16, 1) * (16, 3) = (33, 5) -- iq
wire signed [32:0] multi_1          [0:20];        // --- (16, 1) * (16, 3) = (33, 5) -- iq
wire signed [32:0] multi_2          [0:20];        // --- (16, 1) * (16, 3) = (33, 5) -- iq
//define reg
reg                din_vd_d1;
reg                din_vd_d2;
wire               bias_add_vd;
reg                fir_rst_n;
reg  signed [15:0] shift_reg_i      [0:39];        // --- (16, 1)   
reg  signed [15:0] shift_reg_q      [0:39];        // --- (16, 1)
reg  signed [32:0] prodt_out_i      [0:20];        // --- shift_reg * filt_para => (16, 1)*(16, 3) = (33, 5)
reg  signed [32:0] prodt_out_q      [0:20];        // --- shift_reg * filt_para => (16, 1)*(16, 3) = (33, 5)
reg  signed [33:0] add_s0_i         [0: 9];        // --- (34, 6)
reg  signed [33:0] add_s0_q         [0: 9];        // --- (34, 6)
reg  signed [34:0] add_s1_i         [0: 5];        // --- (35, 7)
reg  signed [34:0] add_s1_q         [0: 5];        // --- (35, 7)
reg  signed [35:0] add_s2_i         [0: 2];        // --- (36, 8)
reg  signed [35:0] add_s2_q         [0: 2];        // --- (36, 8)
reg  signed [36:0] add_s3_i         [0: 1];        // --- (37, 9)
reg  signed [36:0] add_s3_q         [0: 1];        // --- (37, 9)
reg  signed [37:0] fir_out_i;                      // --- (38, 10)
reg  signed [37:0] fir_out_q;                      // --- (38, 10)
reg  signed [38:0] cnn1d_out_i;                    // --- (39, 11)
reg  signed [38:0] cnn1d_out_q;                    // --- (39, 11)

 
// --- dout_vd state signal --- //
reg       state;
reg [4:0] dout_vd_cnt;

// --- load filt para --- //
genvar ii;

assign filt_bias_i = filt_para_i_L[21*16 +: 16];
assign filt_bias_q = filt_para_q_L[21*16 +: 16];

generate
    for (ii = 0; ii < 21; ii = ii + 1) begin : Load_NL_para
        assign filt_para_i[20-ii] = filt_para_i_L[(ii*16) +: 16];
        assign filt_para_q[20-ii] = filt_para_q_L[(ii*16) +: 16];
    end
endgenerate

// -----------------------------------------------------------------------------
// FIR Part Design Start
// -----------------------------------------------------------------------------
// -- din valid signal delay --//
assign din_vd_d0 = din_vd | dout_vd;
always @(posedge clk ) begin
    if(!rst_n) begin
        din_vd_d1 <= 1'b0;
        din_vd_d2 <= 1'b0;
    end else begin
        din_vd_d1 <= din_vd_d0;
        din_vd_d2 <= din_vd_d1;
    end
end

// -- shift register part --//
always @(posedge clk) begin:shift_registering
    integer cnt; 
    if(!rst_n) begin 
        for(cnt=0; cnt<40; cnt=cnt+1) begin
            shift_reg_i[cnt] <= 'd0;
            shift_reg_q[cnt] <= 'd0;
        end
    end else if(fir_rst_n) begin
        for(cnt=0; cnt<40; cnt=cnt+1) begin
            shift_reg_i[cnt] <= 'd0;
            shift_reg_q[cnt] <= 'd0;
        end
    end else begin
        if(din_vd_d0) begin
            shift_reg_i[0] <= xn_i;
            shift_reg_q[0] <= xn_q;
            for(cnt=1; cnt<40; cnt=cnt+1) begin
                shift_reg_i[cnt] <= shift_reg_i[cnt-1];
                shift_reg_q[cnt] <= shift_reg_q[cnt-1];
            end
        end
    end
end

// -- multiply part delay 1T--//
generate
    assign multi_0[0] = xn_i * $signed({filt_para_i[0][15], filt_para_i[0]} - {filt_para_q[0][15], filt_para_q[0]});
    assign multi_1[0] = xn_q * $signed({filt_para_i[0][15], filt_para_i[0]} + {filt_para_q[0][15], filt_para_q[0]});
    assign multi_2[0] = filt_para_q[0] * $signed({xn_i[15], xn_i} - {xn_q[15], xn_q});
    for(ii = 1; ii < 21; ii = ii + 1) begin
        assign multi_0[ii] = shift_reg_i[ii*2-1] * $signed({filt_para_i[ii][15], filt_para_i[ii]} - {filt_para_q[ii][15], filt_para_q[ii]});
        assign multi_1[ii] = shift_reg_q[ii*2-1] * $signed({filt_para_i[ii][15], filt_para_i[ii]} + {filt_para_q[ii][15], filt_para_q[ii]});
        assign multi_2[ii] = filt_para_q[ii] * $signed({shift_reg_i[ii*2-1][15], shift_reg_i[ii*2-1]} - {shift_reg_q[ii*2-1][15], shift_reg_q[ii*2-1]});

    end
endgenerate

always @(posedge clk) begin:multiply 
    integer ii;
    if(!rst_n) begin
        for(ii=0; ii<21; ii=ii+1) begin
            prodt_out_i[ii] <= 'd0;
            prodt_out_q[ii] <= 'd0;
        end
    end
    else begin
        if(din_vd_d0)begin
            for(ii=0; ii<21; ii=ii+1) begin
                prodt_out_i[ii] <= multi_0[ii] + multi_2[ii];
                prodt_out_q[ii] <= multi_1[ii] + multi_2[ii];
            end
        end
    end     
end

// -- adder delay 2T--//
always @(*) begin :addition
    integer ii;

    for(ii=0; ii<10; ii=ii+1) begin
        add_s0_i[ii] = prodt_out_i[2*ii] + prodt_out_i[2*ii+1];
        add_s0_q[ii] = prodt_out_q[2*ii] + prodt_out_q[2*ii+1];
    end
    
    for(ii=0; ii<3; ii=ii+1) begin
        add_s2_i[ii] = add_s1_i[2*ii] + add_s1_i[2*ii+1]; 
        add_s2_q[ii] = add_s1_q[2*ii] + add_s1_q[2*ii+1]; 
    end
           
    fir_out_i = add_s3_i[0] + add_s3_i[1];
    fir_out_q = add_s3_q[0] + add_s3_q[1];
end

always @(posedge clk ) begin:adder
    integer ii;
    if(!rst_n) begin
        for(ii=0; ii<6; ii=ii+1) begin
            add_s1_i[ii] <= 0;
            add_s1_q[ii] <= 0;
        end
            
        for(ii=0; ii<2; ii=ii+1) begin
            add_s3_i[ii] <= 0;
            add_s3_q[ii] <= 0;
        end

    end else begin
        if(din_vd_d1)begin
            add_s1_i[5] <= prodt_out_i[20];
            add_s1_q[5] <= prodt_out_q[20];
            for(ii=0; ii<5; ii=ii+1) begin
                add_s1_i[ii] <= add_s0_i[2*ii] + add_s0_i[2*ii+1];
                add_s1_q[ii] <= add_s0_q[2*ii] + add_s0_q[2*ii+1];
            end
        end
        
        if(din_vd_d2)begin
            add_s3_i[1] <= add_s2_i[2];
            add_s3_q[1] <= add_s2_q[2];
            for(ii=0; ii<1; ii=ii+1) begin
                add_s3_i[ii] <= add_s2_i[2*ii] + add_s2_i[2*ii+1];
                add_s3_q[ii] <= add_s2_q[2*ii] + add_s2_q[2*ii+1];
            end
        end
    end    
end

// --- bias addition (delay 1T)--- //
always @(posedge clk) begin
    if(!rst_n) begin
        cnn1d_out_i <= 'd0;
        cnn1d_out_q <= 'd0;
    end 
    else if(bias_add_vd) begin
        cnn1d_out_i <= fir_out_i + $signed({{7{filt_bias_i[15]}}, filt_bias_i, 15'd0});
        cnn1d_out_q <= fir_out_q + $signed({{7{filt_bias_q[15]}}, filt_bias_q, 15'd0});
    end    
    else begin
        cnn1d_out_i <= 'd0;
        cnn1d_out_q <= 'd0;
    end                                                              
end                                          

// --- fir state design ---//
always @(posedge clk ) begin
    if(!rst_n) begin
        state       <= 1'b0;
        dout_vd_cnt <= 5'd0;
        fir_rst_n   <= 1'b0;
    end else begin
        case (state)
            1'b0 : begin
                if(din_vd) begin
                    if (dout_vd_cnt != 5'd22) 
                        dout_vd_cnt <= dout_vd_cnt + 1'b1;
                    else begin
                        state       <= 1'b1;
                        dout_vd_cnt <= 5'd0;
                    end
                end
            end 
            1'b1 : begin
                if(~(din_vd)) begin
                    if (dout_vd_cnt == 5'd21)
                        fir_rst_n <= 1'b1;
                    if (dout_vd_cnt != 5'd22) begin
                        dout_vd_cnt <= dout_vd_cnt + 1'b1;
                    end else begin
                        state       <= 1'b0;
                        dout_vd_cnt <= 5'd0;
                        fir_rst_n   <= 1'b0;
                    end
                end
            end
        endcase
    end
end

assign bias_add_vd = (state==1'b1);

always @(posedge clk) begin
    if(!rst_n) begin
        dout_vd <= 1'b0;
    end
    else begin
        dout_vd <= bias_add_vd;
    end
end

// data saturation (39, 11) -> (16, 3)
always @(*) begin
    if (cnn1d_out_i[WIDTH_IN-1]) begin
        if (cnn1d_out_i[WIDTH_IN-2:WIDTH_ref-1] == {(WIDTH_IN-WIDTH_ref){1'b1}}) begin
            yn_i = cnn1d_out_i[WIDTH_ref-1:WIDTH_ref-WIDTH_OUT];
        end else begin
            yn_i = {1'b1,{15{1'b0}}};
        end
    end else begin
        if (cnn1d_out_i[WIDTH_IN-2:WIDTH_ref-1] == {(WIDTH_IN-WIDTH_ref){1'b0}}) begin
            yn_i = cnn1d_out_i[WIDTH_ref-1:WIDTH_ref-WIDTH_OUT];
        end else begin
            yn_i = {1'b0,{15{1'b1}}};
        end
    end
end

always @(*) begin
    if (cnn1d_out_q[WIDTH_IN-1]) begin
        if (cnn1d_out_q[WIDTH_IN-2:WIDTH_ref-1] == {(WIDTH_IN-WIDTH_ref){1'b1}}) begin
            yn_q = cnn1d_out_q[WIDTH_ref-1:WIDTH_ref-WIDTH_OUT];
        end else begin
            yn_q = {1'b1,{15{1'b0}}};
        end
    end else begin
        if (cnn1d_out_q[WIDTH_IN-2:WIDTH_ref-1] == {(WIDTH_IN-WIDTH_ref){1'b0}}) begin
            yn_q = cnn1d_out_q[WIDTH_ref-1:WIDTH_ref-WIDTH_OUT];
        end else begin
            yn_q = {1'b0,{15{1'b1}}};
        end
    end
end

endmodule