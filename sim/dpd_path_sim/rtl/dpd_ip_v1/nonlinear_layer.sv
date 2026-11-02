// -----------------------------------------------------------------------------
// --- nonlinear_layer module (delay 36T)
// --- the NL layer of EXPCNN
// --- NL_func: exp[(abs(signal)-centers)**2 * theta]
// --- signal(1 channel)    centers_num:1*12    theta:1*12
// --- NL_output:1 channel
// -----------------------------------------------------------------------------
module nonlinear_layer(
    //input
    clk,
    rst_n,
    din_vd,
    NL_input_i,
    NL_input_q,
    NL_para,
    //core_data
    // grad_0_i_out,
    // grad_0_q_out,
    // grad_1_out,
    // f2_out,
    // f0_out,
    // grad_2_i_out,
    // grad_2_q_out,
    //output
    NL_out_vd,
    NL_out_i,
    NL_out_q
);

input  wire                      clk;
input  wire                      rst_n;
input  wire                      din_vd       [0:6];
input  wire signed [15:0]        NL_input_i   [0:6];           // --- (16, 3)
input  wire signed [15:0]        NL_input_q   [0:6];           // --- (16, 3)
input  wire        [9*4*16-1:0]  NL_para      [0:6];

output reg  signed [15:0]        NL_out_i     [0:6];      // --- (16, 2)
output reg  signed [15:0]        NL_out_q     [0:6];      // --- (16, 2)
output wire                      NL_out_vd    [0:6];    


nl_core u_NL_core_0(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [0]            ),
    .NL_input_i                         (NL_input_i [0]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [0]            ),// --- (16, 3)
    .NL_para                            (NL_para    [0]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [0]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [0]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [0]            )
);

nl_core u_NL_core_1(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [1]            ),
    .NL_input_i                         (NL_input_i [1]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [1]            ),// --- (16, 3)
    .NL_para                            (NL_para    [1]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [1]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [1]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [1]            )
);

nl_core u_NL_core_2(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [2]            ),
    .NL_input_i                         (NL_input_i [2]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [2]            ),// --- (16, 3)
    .NL_para                            (NL_para    [2]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [2]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [2]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [2]            )
);

nl_core u_NL_core_3(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [3]            ),
    .NL_input_i                         (NL_input_i [3]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [3]            ),// --- (16, 3)
    .NL_para                            (NL_para    [3]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [3]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [3]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [3]            )
);

nl_core u_NL_core_4(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [4]            ),
    .NL_input_i                         (NL_input_i [4]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [4]            ),// --- (16, 3)
    .NL_para                            (NL_para    [4]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [4]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [4]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [4]            )
);

nl_core u_NL_core_5(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [5]            ),
    .NL_input_i                         (NL_input_i [5]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [5]            ),// --- (16, 3)
    .NL_para                            (NL_para    [5]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [5]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [5]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [5]            )
);

nl_core u_NL_core_6(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .din_vd                             (din_vd     [6]            ),
    .NL_input_i                         (NL_input_i [6]            ),// --- (16, 3)
    .NL_input_q                         (NL_input_q [6]            ),// --- (16, 3)
    .NL_para                            (NL_para    [6]            ),// --- (16, 3)
    .NL_out_i                           (NL_out_i   [6]            ),// --- (16, 2)
    .NL_out_q                           (NL_out_q   [6]            ),// --- (16, 2)
    .NL_out_vd                          (NL_out_vd  [6]            )
);




endmodule