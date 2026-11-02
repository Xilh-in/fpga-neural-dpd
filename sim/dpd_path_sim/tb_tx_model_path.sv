`timescale 1ns/1ps
// Simulation only. The DUT is the real data_ctrl, not a replacement datapath.
module tb_tx_model_path;
  parameter SIM_DIR = "D:/vivado_example/dpd_path_sim/simulation";
  localparam integer N = 1024;
  reg clk_axi = 0, clk_ad9371 = 0;
  always #5 clk_axi = ~clk_axi;
  always #8.138 clk_ad9371 = ~clk_ad9371;
  reg rst_n = 0, tx_vld = 0, dpd_en = 0;
  reg tx_data_en = 0, tx_data_wr = 0;
  reg [15:0] tx_data_addr = 0;
  reg [31:0] tx_data_wdata = 0;
  reg coe_en = 0, coe_wr = 0;
  reg [9:0] coe_addr = 0;
  reg [15:0] coe_wdata = 0;
  reg [2:0] ch_sel = 0;
  reg [5:0] cap_data_cmd = 0;
  reg [15:0] cap_rd_addr = 0;
  wire [31:0] tx_data, cap_data_rdata;
  wire cap_done;
  reg [31:0] samples [0:N-1], expected_model [0:N-1];
  reg [15:0] coefficients [0:575];
  reg seen [0:N-1];
  integer errors = 0, checks = 0, phase = -1, cycle = 0;
  integer phase_count [0:3];
  integer i, j, k, trace_fd, cap_fd, summary_fd, probe_fd;
  reg trace_en = 0;
  string sim_dir;
  reg [31:0] direct_before, model_before, golden, final_golden;
  reg valid_before;
  integer sample_index;
  reg [31:0] cap_tx, cap_model, cap_final;

  data_ctrl #(.DATA_LENGTH(N)) dut (
    .clk_axi(clk_axi), .clk_ad9371(clk_ad9371), .rst_n(rst_n),
    .tx_data(tx_data), .rx_data(32'd0),
    .align_en(1'b0), .delay(10'd0), .apc_k_i(32'sd16777216), .apc_k_q(32'sd0),
    .cap_data_cmd(cap_data_cmd), .cap_len(16'd1024), .trigger_point(32'd0),
    .cap_rd_addr(cap_rd_addr), .cap_data_rdata(cap_data_rdata),
    .tx_vld(tx_vld), .tx_data_en(tx_data_en), .tx_data_wr(tx_data_wr),
    .tx_data_addr(tx_data_addr), .tx_data_wdata(tx_data_wdata), .tx_data_rdata(),
    .ch_sel(ch_sel), .dpd_en(dpd_en), .dpd_coe_en(coe_en), .dpd_coe_wr(coe_wr),
    .dpd_coe_addr(coe_addr), .dpd_coe_wdata(coe_wdata), .dpd_coe_rdata(), .dpd_out(),
    .cyclic_en(1'b0), .cyclic_data_en(1'b0), .cyclic_data_wr(1'b0),
    .cyclic_data_addr(16'd0), .cyclic_data_wdata(32'd0), .cyclic_data_rdata(),
    .cap_done(cap_done)
  );

  function automatic integer find_sample(input reg [31:0] word_value);
    integer n;
    begin
      find_sample = -1;
      for (n=0; n<N; n=n+1)
        if (word_value === samples[n]) find_sample = n;
    end
  endfunction

  // Explicit sign extension also keeps CSV output consistent across simulators.
  function automatic integer iq_i(input reg [31:0] word_value);
    iq_i = {{16{word_value[15]}},word_value[15:0]};
  endfunction
  function automatic integer iq_q(input reg [31:0] word_value);
    iq_q = {{16{word_value[31]}},word_value[31:16]};
  endfunction

  function automatic [15:0] sat16(input integer value);
    if (value > 32767) sat16 = 16'h7fff;
    else if (value < -32768) sat16 = 16'h8000;
    else sat16 = value[15:0];
  endfunction

  function automatic [31:0] subtract_sat(input reg [31:0] a, b);
    integer vi, vq;
    begin
      vi = $signed(a[15:0]) - $signed(b[15:0]);
      vq = $signed(a[31:16]) - $signed(b[31:16]);
      subtract_sat = {sat16(vq), sat16(vi)};
    end
  endfunction

  task automatic check_word(input string label_text, input reg [31:0] actual, expected);
    begin
      checks = checks + 1;
      if (actual !== expected) begin
        errors = errors + 1;
        if (errors <= 12)
          $display("PATH_ERROR %s phase=%0d cycle=%0d actual=%h expected=%h",
                   label_text, phase, cycle, actual, expected);
      end
    end
  endtask

  task automatic read_node(input integer node_number, input integer address,
                           output reg [31:0] value);
    begin
      @(negedge clk_axi);
      cap_data_cmd = 6'd8 | node_number;
      cap_rd_addr = address;
      repeat (6) @(negedge clk_axi);
      value = cap_data_rdata;
    end
  endtask

  // Read operands BEFORE the edge; compare with the registered result AFTER NBA.
  // This avoids inventing a relative shift while comparing CSV columns.
  always @(posedge clk_ad9371) begin
    cycle = cycle + 1;
    if (trace_en) begin
      direct_before = {dut.tx_dealy_q, dut.tx_dealy_i};
      model_before = dut.node_G_data;
      valid_before = dut.dout_vd;
      sample_index = find_sample(direct_before);
      #1;
      phase_count[phase] = phase_count[phase] + 1;
      if (phase == 3) begin
        check_word("TX_STOP", tx_data, 32'd0);
      end else begin
        if (sample_index < 0) check_word("TX_SAMPLE_NOT_FOUND", 32'd0, 32'd1);
        if (phase == 0 || phase == 2) begin
          check_word("BYPASS_OR_DISABLED", tx_data, direct_before);
          if (phase == 2) check_word("DISABLED_VALID", {31'd0,valid_before}, 32'd0);
        end else if (sample_index >= 0) begin
          seen[sample_index] = 1;
          golden = expected_model[sample_index];
          final_golden = subtract_sat(direct_before, golden);
          check_word("MODEL_SAME_SAMPLE", model_before, golden);
          check_word("TX_MINUS_MODEL", tx_data, final_golden);
          check_word("MODEL_VALID", {31'd0,valid_before}, 32'd1);
        end
      end
      $fwrite(trace_fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
        phase, cycle, sample_index, iq_i(direct_before),
        iq_q(direct_before), iq_i(model_before),
        iq_q(model_before), iq_i(tx_data),
        iq_q(tx_data), valid_before);
    end
  end

  initial begin
    sim_dir = SIM_DIR;
    if ($value$plusargs("SIM_DIR=%s", sim_dir)) begin end
    $display("PATH_SIM_DIR=%s", sim_dir);
    // Explicit checks prevent a missing .mem file from silently becoming zero data.
    probe_fd = $fopen({sim_dir,"/samples.mem"},"r");
    if (!probe_fd) $fatal(1,"Cannot find samples.mem. Set SIM_DIR in the TB.");
    $fclose(probe_fd);
    probe_fd = $fopen({sim_dir,"/coefficients.mem"},"r");
    if (!probe_fd) $fatal(1,"Cannot find coefficients.mem.");
    $fclose(probe_fd);
    probe_fd = $fopen({sim_dir,"/expected_model.mem"},"r");
    if (!probe_fd) $fatal(1,"Cannot find expected_model.mem.");
    $fclose(probe_fd);
    $readmemh({sim_dir,"/samples.mem"},samples);
    $readmemh({sim_dir,"/coefficients.mem"},coefficients);
    $readmemh({sim_dir,"/expected_model.mem"},expected_model);
    for(i=0;i<N;i=i+1) seen[i]=0;
    for(i=0;i<4;i=i+1) phase_count[i]=0;
    trace_fd=$fopen({sim_dir,"/path_trace.csv"},"w");
    cap_fd=$fopen({sim_dir,"/cap_tx_model.csv"},"w");
    summary_fd=$fopen({sim_dir,"/path_result.txt"},"w");
    if (!trace_fd || !cap_fd || !summary_fd) $fatal(1,"Cannot write simulation output files.");
    $fwrite(trace_fd,"phase,cycle,sample_index,tx_delay_i,tx_delay_q,used_model_i,used_model_q,tx_final_i,tx_final_q,raw_valid\n");
    $fwrite(cap_fd,"index,sample_index,tx_i,tx_q,model_i,model_q,final_i,final_q\n");
    repeat(10) @(negedge clk_axi);
    rst_n=1;
    for(i=0;i<N;i=i+1) begin
      @(negedge clk_axi);
      tx_data_en=1;tx_data_wr=1;tx_data_addr=i;tx_data_wdata=samples[i];
    end
    @(negedge clk_axi);tx_data_en=0;tx_data_wr=0;
    // Hold the coefficient bus stable across the two-clock CDC of enable/write.
    for(i=0;i<576;i=i+1) begin
      @(negedge clk_axi);coe_addr=i;coe_wdata=coefficients[i];coe_wr=1;
      repeat(10) @(negedge clk_axi);
      coe_en=1;
      repeat(10) @(negedge clk_axi);
      coe_en=0;
      repeat(10) @(negedge clk_axi);
    end
    coe_wr=0;
    repeat(10) @(negedge clk_ad9371);
    for(i=0;i<576;i=i+1)
      if(dut.u_dpd_top.dpd_coe[i] !== coefficients[i]) $fatal(1,"Coefficient mismatch at %0d",i);
    $display("COEFFICIENTS_PASS 576/576");
    tx_vld=1;dpd_en=1;ch_sel=0;
    repeat(3*N) @(negedge clk_ad9371);
    phase=0;trace_en=1;
    repeat(N) @(negedge clk_ad9371);
    trace_en=0;ch_sel=1;
    repeat(12) @(negedge clk_ad9371);
    phase=1;trace_en=1;
    cap_data_cmd=6'd16;
    repeat(8) @(negedge clk_ad9371);
    cap_data_cmd=0;
    repeat(4*N) @(negedge clk_ad9371);
    trace_en=0;
    // E done alone can arrive before F/G/H in this RX=0 test. Wait for all.
    if(cap_done !== 1'b1 || dut.cap_F_done !== 1'b1 || dut.cap_H_done !== 1'b1)
      $fatal(1,"Capture failed to finish E/F/H.");
    repeat(4) @(negedge clk_ad9371);
    for(i=0;i<N;i=i+1) begin
      read_node(5,i,cap_tx);read_node(6,i,cap_model);read_node(7,i,cap_final);
      k=find_sample(cap_tx);
      if(k<0) check_word("CAPTURE_TX_NOT_FOUND",32'd0,32'd1);
      else begin
        check_word("CAPTURE_MODEL_SAME_SAMPLE",cap_model,expected_model[k]);
        check_word("CAPTURE_FINAL",cap_final,subtract_sat(cap_tx,expected_model[k]));
      end
      check_word("CAPTURE_ARITHMETIC",cap_final,subtract_sat(cap_tx,cap_model));
      $fwrite(cap_fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",i,k,
        iq_i(cap_tx),iq_q(cap_tx),iq_i(cap_model),
        iq_q(cap_model),iq_i(cap_final),iq_q(cap_final));
    end
    @(negedge clk_axi);cap_data_cmd=6'd32;
    repeat(10) @(negedge clk_ad9371);cap_data_cmd=0;
    repeat(10) @(negedge clk_ad9371);
    dpd_en=0;
    repeat(160) @(negedge clk_ad9371);
    phase=2;trace_en=1;
    repeat(N) @(negedge clk_ad9371);
    trace_en=0;tx_vld=0;
    repeat(100) @(negedge clk_ad9371);
    phase=3;trace_en=1;
    repeat(64) @(negedge clk_ad9371);
    trace_en=0;
    for(i=0;i<N;i=i+1) if(!seen[i]) check_word("MISSING_SAMPLE_COVERAGE",32'd0,32'd1);
    for(i=0;i<4;i=i+1) if(phase_count[i]==0) check_word("MISSING_PHASE",32'd0,32'd1);
    $fwrite(summary_fd,"CHECKS=%0d\nERRORS=%0d\nBYPASS_CYCLES=%0d\nDPD_CYCLES=%0d\nDISABLED_CYCLES=%0d\nSTOP_CYCLES=%0d\n",
      checks,errors,phase_count[0],phase_count[1],phase_count[2],phase_count[3]);
    $fclose(trace_fd);$fclose(cap_fd);
    if(errors!=0) begin
      $fwrite(summary_fd,"PATH_SIM_FAIL\n");$fclose(summary_fd);
      $fatal(1,"PATH_SIM_FAIL errors=%0d checks=%0d",errors,checks);
    end
    $fwrite(summary_fd,"PATH_SIM_PASS\n");$fclose(summary_fd);
    $display("PATH_SIM_PASS checks=%0d errors=0 captured=1024 coverage=1024",checks);
    $finish;
  end
  initial begin
    #5000000;
    $fatal(1,"PATH_SIM_TIMEOUT: expected completion within 5 ms simulated time.");
  end
endmodule
