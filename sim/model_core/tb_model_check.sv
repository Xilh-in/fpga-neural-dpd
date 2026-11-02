`timescale 1ns/1ps
module tb_model_check;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst_n = 0;
  reg coe_en = 0, coe_wr = 0, din_vd = 0;
  reg [9:0] coe_addr = 0;
  reg [15:0] coe_wdata = 0;
  reg signed [15:0] xn_i = 0, xn_q = 0;
  wire dout_vd;
  wire signed [15:0] yn_i, yn_q, coe_rdata;
  reg [15:0] coefficients [0:575];
  reg [31:0] samples [0:1023];
  integer i, k, fd;

  dpd_top dut(.clk(clk), .rst_n(rst_n), .dpd_coe_en(coe_en), .dpd_coe_wr(coe_wr),
              .dpd_coe_addr(coe_addr), .dpd_coe_wdata(coe_wdata), .din_vd(din_vd),
              .xn_i(xn_i), .xn_q(xn_q), .dout_vd(dout_vd), .yn_i(yn_i), .yn_q(yn_q),
              .dpd_coe_rdata(coe_rdata));

  initial begin
    $readmemh("coefficients.mem", coefficients);
    $readmemh("samples.mem", samples);
    repeat (4) @(negedge clk);
    rst_n = 1;
    for (i=0; i<576; i=i+1) begin
      @(negedge clk);
      coe_en = 1; coe_wr = 1; coe_addr = i; coe_wdata = coefficients[i];
    end
    @(negedge clk);
    coe_en = 0; coe_wr = 0;
    for (i=0; i<576; i=i+1)
      if (dut.dpd_coe[i] !== coefficients[i]) $fatal(1, "coefficient mismatch %0d", i);
    fd = $fopen("rtl_trace.csv", "w");
    $fwrite(fd, "cycle,input_i,input_q,valid,output_i,output_q,acc_i,acc_q");
    for (k=0; k<7; k=k+1) $fwrite(fd, ",l1_i%0d,l1_q%0d,l2_i%0d,l2_q%0d", k,k,k,k);
    $fwrite(fd, "\n");
    din_vd = 1;
    // Prefix/suffix are zero. Comparison excludes missing captured history/future.
    for (i=0; i<1184; i=i+1) begin
      if (i>=80 && i<1104) begin
        xn_i = samples[i-80][15:0]; xn_q = samples[i-80][31:16];
      end else begin xn_i = 0; xn_q = 0; end
      @(posedge clk); #1;
      $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d", i, xn_i, xn_q, dout_vd, yn_i, yn_q,
              $signed(dut.u_ExpCNN.u_Linear_layer_1.L_out_i_L),
              $signed(dut.u_ExpCNN.u_Linear_layer_1.L_out_q_L));
      for (k=0; k<7; k=k+1)
        $fwrite(fd, ",%0d,%0d,%0d,%0d", $signed(dut.u_ExpCNN.L1_out_i[k]),
                 $signed(dut.u_ExpCNN.L1_out_q[k]), $signed(dut.u_ExpCNN.L2_out_i[k]),
                 $signed(dut.u_ExpCNN.L2_out_q[k]));
      $fwrite(fd, "\n");
      @(negedge clk);
    end
    $fclose(fd);
    $display("MODEL_CHECK_FINISHED");
    $finish;
  end
endmodule
