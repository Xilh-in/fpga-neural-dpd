// -----------------------------------------------------------------------------
// --- cordic_exp module
// --- 通过cordic算法实现exp函数近似计算
// --- model out delay = 20T
// -----------------------------------------------------------------------------

module cordic_exp(
    clk,
    rst_n,
    din_vd,
    din,
    exp_dout_vd,
    exp_out
);

parameter DW = 25;
parameter NW  = 7;
parameter [4*17-1:0] shift_num = { 4'd15, 4'd14, 4'd13, 4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 
                                        4'd5, 4'd4, 4'd4, 4'd3, 4'd2, 4'd1};

// input/output port
input                               clk                        ;
input                               rst_n                      ;
input                               din_vd                     ;
input      signed  [DW-1: 0]        din                        ;// - (DW, NW)

output                              exp_dout_vd                ;
output     signed  [DW-1: 0]        exp_out                    ;

// define relative wires
wire    signed     [DW+19: 0]        din_divide_L                ;// - (DW, NW) * (20, 2) --> (DW+20, NW+2)
wire    signed     [DW+19: 0]        din_divide_abs_L            ;// - (DW+20, NW+2)
wire    signed     [NW+21: 0]        din_integer_L               ;// - (NW+2, NW+2) * (20, 1) --> (NW+22, NW+3)
wire    signed     [DW- 1: 0]        din_integer                 ;// - (DW, NW)

// define relative regs
reg     signed     [DW-1: 0]        din_d                        ;
reg     signed     [NW+1: 0]        din_mod                      ;// - (NW+2, NW+2)
reg     signed     [NW+1: 0]        din_mod_d        [0:18]      ; 
reg     signed     [DW-1: 0]        din_remainder                ;// - (1, 20, 15)
reg     signed     [DW-1: 0]        x                [0:17]      ;
reg     signed     [DW-1: 0]        y                [0:17]      ;
reg     signed     [DW-1: 0]        z                [0:17]      ;
reg     signed     [  17: 0]        angle            [0:16]      ;//14 (30 - 15)
reg     signed     [DW-1: 0]        exp_remainder_out            ;
reg     signed     [DW-1: 0]        exp_out_L                    ;
reg                [  19: 0]        din_vd_d                     ;//18


// --- initial angle ---//
always @(*) begin
    if(!rst_n) begin                          // angle           tanh(angle)                         
        angle[0]  = 18'b100011001001111101; // 0.549306,       2^(-1)
        angle[1]  = 18'b010000010110001010; // 0.255413,       2^(-2)
        angle[2]  = 18'b001000000010101100; // 0.125657,       2^(-3)
        angle[3]  = 18'b000100000000010101; // 0.062582,       2^(-4)
        angle[4]  = 18'b000100000000010101; // 0.062582,       2^(-4) (重复迭代一次)
        angle[5]  = 18'b000010000000000010; // 0.031260，      2^(-5)
        angle[6]  = 18'b000001000000000000; // 0.015626，      2^(-6)
        angle[7]  = 18'b000000100000000000; // 0.007813，      2^(-7)
        angle[8]  = 18'b000000010000000000; // 0.003906250，   2^(-8)
        angle[9]  = 18'b000000001000000000; // 0.001953125，   2^(-9)
        angle[10] = 18'b000000000100000000; // 0.0009765625，  2^(-10)
        angle[11] = 18'b000000000010000000; // 0.00048828125， 2^(-11)
        angle[12] = 18'b000000000001000000; // 0.000244140625，2^(-12)
        angle[13] = 18'b000000000000100000; // 0.000122070313，2^(-13)
        angle[14] = 18'b000000000000100000; // 0.000122070313，2^(-13)(重复迭代一次)
        angle[15] = 18'b000000000000010000; // 0.000122070313，2^(-14)
        angle[16] = 18'b000000000000001000; // 0.000122070313，2^(-15)
    end
end

// --- expand the range of cordic_exp : delay 2T --- //
assign din_divide_L = din * $signed(20'b01011100010101010001);     // - (DW, NW) * (20, 2) --> (DW+20, NW+2)
assign din_divide_abs_L = (din_divide_L[DW+19])? {1'b1, ~din_divide_L[DW+19-1:0] + 1'b1} : din_divide_L;

assign din_integer_L  = {1'b0, din_mod[NW:0]} * 20'b01011000101110010000;     // - (NW+2, NW+2) * (20, 1) --> (NW+22, NW+3)
assign din_integer    = din_integer_L[NW+18 -: DW];  // (NW+22, NW+3) -> (DW, NW)


// --- din_vd signal shift resigter ---//
always @(posedge clk) begin :valid_signal_shift
    integer cnt;
    if(!rst_n)
        din_vd_d <= 'd0;
    else
        din_vd_d <= {din_vd_d[18:0], din_vd};
end

always @(posedge clk) begin
    if(!rst_n) begin
        din_d        <= 'd0;
        din_mod      <= 'd0;
    end else if(din_vd) begin
        din_d        <= din;
        din_mod      <= din_divide_abs_L[DW+19 -: NW+2];
    end
end


always @(posedge clk) begin :expand_exp_range
    integer ii;
    if(!rst_n) begin
        din_remainder <= 'd0;
        for (ii = 0; ii < 19; ii = ii + 1) 
            din_mod_d[ii] <= 'd0;
    end else begin
        if(din_vd_d[0]) begin
            din_remainder  <= (din_d[DW-1])? din_d + din_integer : din_d - din_integer;
            din_mod_d[0]   <= din_mod;
        end
        for (ii = 1; ii < 19; ii = ii + 1) begin
            if(din_vd_d[ii])
                din_mod_d[ii] <= din_mod_d[ii-1];
        end  
    end
end


// --- cordic exp: delay for 18T ---//
always @(posedge clk) begin:cordic_exp
    integer cnt;
    if(!rst_n) begin
        for (cnt = 0; cnt < 18; cnt = cnt + 1 ) begin
            x[cnt] <= 'd0;
            y[cnt] <= 'd0;
            z[cnt] <= 'd0;
        end
    end else begin
        if(din_vd_d[1]) begin
            // initial  
            x[0] <= 25'b0000001001101010001111010; //（1/0.8281593630169717=1.20749706402421）
            y[0] <= 25'd0;
            z[0] <= din_remainder;
        end
        for (cnt = 1; cnt < 18; cnt = cnt + 1) begin
            if(din_vd_d[cnt+1]) begin
                if(z[cnt-1][DW-1]) begin
                    x[cnt] <= x[cnt-1] - (y[cnt-1] >>> shift_num[(cnt-1)*4+:4]);
                    y[cnt] <= y[cnt-1] - (x[cnt-1] >>> shift_num[(cnt-1)*4+:4]);
                    z[cnt] <= z[cnt-1] + $signed({{NW{1'b0}}, angle[cnt-1]});
                end 
                else begin
                    x[cnt] <= x[cnt-1] + (y[cnt-1] >>> shift_num[(cnt-1)*4+:4]);
                    y[cnt] <= y[cnt-1] + (x[cnt-1] >>> shift_num[(cnt-1)*4+:4]);
                    z[cnt] <= z[cnt-1] - $signed({{NW{1'b0}}, angle[cnt-1]});
                end
            end
        end
    end
end

always @(*) begin
    exp_remainder_out = x[17] + y[17];
    exp_out_L   = (din_mod_d[18][NW+1])? (exp_remainder_out >>> din_mod_d[18][NW:0]): (exp_remainder_out <<< din_mod_d[18][NW:0]);
end

assign exp_out     = exp_out_L; // (DW, NW) 
assign exp_dout_vd = din_vd_d[19];

endmodule