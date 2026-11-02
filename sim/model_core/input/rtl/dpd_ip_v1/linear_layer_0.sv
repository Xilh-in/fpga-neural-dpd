// -----------------------------------------------------------------------------
// --- linear_layer_0 module
// --- the first layer of EXPCNN
// --- 1-D CNN (1 channel to 3 channels)
// --- input(1 channel) --> output(3 channel)
// -----------------------------------------------------------------------------
module linear_layer_0(
    //input
    clk,
    rst_n,
    din_vd,
    xn_i,
    xn_q,
    filt_para,
    //output
    L_out_vd,
    L_out_i,
    L_out_q
);

input  wire                          clk;
input  wire                          rst_n;
input  wire                          din_vd;
input  wire signed [15:0]            xn_i;
input  wire signed [15:0]            xn_q;
input  wire        [(21+1)*2*16-1:0] filt_para [0:6];

output wire                          L_out_vd  [0:6];
output wire signed [15:0]            L_out_i   [0:6];
output wire signed [15:0]            L_out_q   [0:6];

// --- filt_para_wire signal --- //
wire signed [22*16-1:0]  filt_para_i [0:6];        // --- (16, 3)
wire signed [22*16-1:0]  filt_para_q [0:6];        // --- (16, 3)

// --- load filt_para --- //
generate
    assign filt_para_i[0] = filt_para[0][22*16-1  :       0];
    assign filt_para_q[0] = filt_para[0][2*22*16-1:   22*16];

    assign filt_para_i[1] = filt_para[1][22*16-1  :       0];
    assign filt_para_q[1] = filt_para[1][2*22*16-1:   22*16];

    assign filt_para_i[2] = filt_para[2][22*16-1  :       0];
    assign filt_para_q[2] = filt_para[2][2*22*16-1:   22*16];

    assign filt_para_i[3] = filt_para[3][22*16-1  :       0];
    assign filt_para_q[3] = filt_para[3][2*22*16-1:   22*16];

    assign filt_para_i[4] = filt_para[4][22*16-1  :       0];
    assign filt_para_q[4] = filt_para[4][2*22*16-1:   22*16];

    assign filt_para_i[5] = filt_para[5][22*16-1  :       0];
    assign filt_para_q[5] = filt_para[5][2*22*16-1:   22*16];

    assign filt_para_i[6] = filt_para[6][22*16-1  :       0];
    assign filt_para_q[6] = filt_para[6][2*22*16-1:   22*16];
endgenerate

cnn0_1d u_CNN0_1d_0(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[0]    ),
    .filt_para_q_L  (filt_para_q[0]    ),
    .dout_vd        (L_out_vd   [0]    ),
    .yn_i           (L_out_i    [0]    ),
    .yn_q           (L_out_q    [0]    )
);

cnn0_1d u_CNN0_1d_1(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[1]    ),
    .filt_para_q_L  (filt_para_q[1]    ),
    .dout_vd        (L_out_vd   [1]    ),
    .yn_i           (L_out_i    [1]    ),
    .yn_q           (L_out_q    [1]    )
);

cnn0_1d u_CNN0_1d_2(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[2]    ),
    .filt_para_q_L  (filt_para_q[2]    ),
    .dout_vd        (L_out_vd   [2]    ),
    .yn_i           (L_out_i    [2]    ),
    .yn_q           (L_out_q    [2]    )
);

cnn0_1d u_CNN0_1d_3(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[3]    ),
    .filt_para_q_L  (filt_para_q[3]    ),
    .dout_vd        (L_out_vd   [3]    ),
    .yn_i           (L_out_i    [3]    ),
    .yn_q           (L_out_q    [3]    )
);

cnn0_1d u_CNN0_1d_4(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[4]    ),
    .filt_para_q_L  (filt_para_q[4]    ),
    .dout_vd        (L_out_vd   [4]    ),
    .yn_i           (L_out_i    [4]    ),
    .yn_q           (L_out_q    [4]    )
);

cnn0_1d u_CNN0_1d_5(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[5]    ),
    .filt_para_q_L  (filt_para_q[5]    ),
    .dout_vd        (L_out_vd   [5]    ),
    .yn_i           (L_out_i    [5]    ),
    .yn_q           (L_out_q    [5]    )
);

cnn0_1d u_CNN0_1d_6(
    .clk            (clk               ),
    .rst_n          (rst_n             ),
    .din_vd         (din_vd            ),
    .xn_i           (xn_i              ),
    .xn_q           (xn_q              ),
    .filt_para_i_L  (filt_para_i[6]    ),
    .filt_para_q_L  (filt_para_q[6]    ),
    .dout_vd        (L_out_vd   [6]    ),
    .yn_i           (L_out_i    [6]    ),
    .yn_q           (L_out_q    [6]    )
);

endmodule