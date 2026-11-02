// -----------------------------------------------------------------------------
// --- cordic_abs module
// --- 通过cordic算法实现复数求模abs函数近似计算
// --- delay = (EPC+1)T  迭代（EPC-1）次
// -----------------------------------------------------------------------------

module cordic_abs(
    clk,
    rst_n,
    din_vd,
    din_x,
    din_y,
    abs_dout_vd,
    abs_out
);

parameter DW  = 16;
parameter NW  = 1;
parameter EPC = 8;

// input/output port
input wire                  clk;
input wire                  rst_n;
input wire                  din_vd;
input wire signed  [DW-1:0] din_x; 
input wire signed  [DW-1:0] din_y; 

output wire                 abs_dout_vd;
output wire signed [DW  :0] abs_out;

// define relative regs
reg signed  [DW+16-1:0]       x                [0:EPC-1];  // (DW+16, NW+1)
reg signed  [DW+16-1:0]       y                [0:EPC-1];  // (DW+16, NW+1)
reg         [EPC :0]          din_vd_shift_reg          ;

// define ralative wires
wire signed [DW-1   :0]   din_x_abs;             // (DW, NW)
wire signed [DW-1   :0]   din_y_abs;             // (DW, NW)
reg  signed [DW+16-1:0]   x_initial;             // (DW, NW)*(16, 1) -> (DW+16, NW+1)
reg  signed [DW+16-1:0]   y_initial;             // (DW, NW)*(16, 1) -> (DW+16, NW+1)

// --- negative to positive number  and extend 1 bits integer --- //
assign din_x_abs = (din_x[DW-1])?  -din_x : din_x;
assign din_y_abs = (din_y[DW-1])?  -din_y : din_y;

// --- din_vd signal shift resigter ---//
always @(posedge clk) begin :valid_signal_shift
    integer cnt;
    if(!rst_n) begin
        din_vd_shift_reg <= 'd0;
    end else
        din_vd_shift_reg <= {din_vd_shift_reg[EPC-1:0], din_vd};
end

// --- initial x and y  delay 1T--- //
always @(posedge clk) begin
    if(!rst_n) begin
        x_initial <= 'd0;
        y_initial <= 'd0;
    end else if(din_vd) begin                    
        x_initial <= din_x_abs * $signed(16'b0100110110111010); // (1 / 1.646760256960988 = 0.6072529349476099)  (DW, NW)*(16, 1) -> (DW+16, NW+1)
        y_initial <= din_y_abs * $signed(16'b0100110110111010); // (1 / 1.646760256960988 = 0.6072529349476099)  (DW, NW)*(16, 1) -> (DW+16, NW+1)
    end
end


// --- cordic exp: delay for 8T ---//
always @(posedge clk) begin:cordic_abs
    integer cnt;
    if(!rst_n) begin
        for (cnt = 0; cnt < EPC; cnt = cnt + 1 ) begin
            x[cnt] <= 'd0;
            y[cnt] <= 'd0;
        end
    end else begin
        if(din_vd_shift_reg[0]) begin
            // initial 
            x[0] <= x_initial;
            y[0] <= y_initial;
        end
        for (cnt = 1; cnt < EPC; cnt = cnt + 1) begin
            if(din_vd_shift_reg[cnt]) begin
                if(y[cnt-1][DW+15]) begin
                    x[cnt] <= x[cnt-1] - (y[cnt-1] >>> (cnt-1));
                    y[cnt] <= y[cnt-1] + (x[cnt-1] >>> (cnt-1));
                end 
                else if(!y[cnt-1][DW+15]) begin
                    x[cnt] <= x[cnt-1] + (y[cnt-1] >>> (cnt-1));
                    y[cnt] <= y[cnt-1] - (x[cnt-1] >>> (cnt-1));
                end
            end
        end
    end
end

assign abs_out     = x[EPC-1][DW+16-1 -: (DW+1)];
assign abs_dout_vd = din_vd_shift_reg[EPC];

endmodule