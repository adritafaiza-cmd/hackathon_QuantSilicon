// quantsilicon_top.sv
// Top-level integration of QuantSilicon V1 trading pipeline
// Combines feature extraction, signal generation, and risk management

import fxp_pkg::*;

module quantsilicon_top (
    input  logic                clk,
    input  logic                rst_n,
    
    // Top-level input stream interface
    input  logic                in_valid,
    output logic                in_ready,
    input  logic signed [31:0]  price,       // Q16.16
    input  logic signed [31:0]  position,    // Q16.16
    input  logic signed [31:0]  beta,        // Q16.16
    
    // Top-level output stream interface
    output logic                out_valid,
    input  logic                out_ready,
    output logic signed [31:0]  signal_out,  // Q16.16
    output logic                allow_trade,
    output logic                kill_switch
);

    // =========================================================================
    // Feature Engine Signals
    // =========================================================================
    logic                feat_in_valid;
    logic                feat_in_ready;
    logic signed [31:0]  feat_price_in;
    logic                feat_out_valid;
    logic                feat_out_ready;
    logic signed [31:0]  feat_ret_out;
    logic signed [31:0]  feat_ema_out;

    // =========================================================================
    // Signal Engine Signals
    // =========================================================================
    logic                sig_in_valid;
    logic                sig_in_ready;
    logic signed [31:0]  sig_ret_in;
    logic signed [31:0]  sig_ema_in;
    logic                sig_out_valid;
    logic                sig_out_ready;
    logic signed [31:0]  sig_signal_out;

    // =========================================================================
    // Risk Engine Signals
    // =========================================================================
    logic                risk_in_valid;
    logic                risk_in_ready;
    logic signed [31:0]  risk_position_in;
    logic signed [31:0]  risk_beta_in;
    logic                risk_out_valid;
    logic                risk_out_ready;
    logic                risk_allow_trade;
    logic                risk_kill_switch;

    // =========================================================================
    // Output Buffering for Branch Alignment
    // =========================================================================
    // Single-entry buffers to hold outputs until both branches are ready
    logic                signal_buf_valid;
    logic signed [31:0]  signal_buf_data;
    
    logic                risk_buf_valid;
    logic                risk_buf_allow;
    logic                risk_buf_kill;

    // =========================================================================
    // Input Distribution & Handshake
    // =========================================================================
    // Top accepts input only when both feature and risk engines are ready
    assign in_ready = feat_in_ready && risk_in_ready;
    
    // Distribute input to both parallel branches
    assign feat_in_valid = in_valid && risk_in_ready;  // Only valid if both ready
    assign feat_price_in = price;
    
    assign risk_in_valid = in_valid && feat_in_ready;  // Only valid if both ready
    assign risk_position_in = position;
    assign risk_beta_in = beta;

    // =========================================================================
    // Feature -> Signal Pipeline Chaining
    // =========================================================================
    // Direct connection: feature output -> signal input
    assign sig_in_valid = feat_out_valid;
    assign sig_ret_in = feat_ret_out;
    assign sig_ema_in = feat_ema_out;
    assign feat_out_ready = sig_in_ready;

    // =========================================================================
    // Output Branch Buffering Logic
    // =========================================================================
    // Signal branch buffer: latch when signal_engine produces output
    // Ready to accept from engines if buffer empty OR if we're popping this cycle
wire pop = out_valid && out_ready;

assign sig_out_ready  = !signal_buf_valid || pop;
assign risk_out_ready = !risk_buf_valid   || pop;

// Signal buffer
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    signal_buf_valid <= 1'b0;
    signal_buf_data  <= '0;
  end else begin
    if (sig_out_valid && sig_out_ready) begin
      signal_buf_valid <= 1'b1;
      signal_buf_data  <= sig_signal_out;
    end else if (pop) begin
      signal_buf_valid <= 1'b0;
    end
  end
end

// Risk buffer
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    risk_buf_valid <= 1'b0;
    risk_buf_allow <= 1'b0;
    risk_buf_kill  <= 1'b0;
  end else begin
    if (risk_out_valid && risk_out_ready) begin
      risk_buf_valid <= 1'b1;
      risk_buf_allow <= risk_allow_trade;
      risk_buf_kill  <= risk_kill_switch;
    end else if (pop) begin
      risk_buf_valid <= 1'b0;
    end
  end
end

assign out_valid    = signal_buf_valid && risk_buf_valid;
assign signal_out   = signal_buf_data;
assign allow_trade  = risk_buf_allow;
assign kill_switch  = risk_buf_kill;


    // =========================================================================
    // Submodule Instantiations
    // =========================================================================
    
    // Feature extraction: price -> (return, EMA)
    feature_engine u_feature_engine (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_valid   (feat_in_valid),
        .in_ready   (feat_in_ready),
        .price_in   (feat_price_in),
        .out_valid  (feat_out_valid),
        .out_ready  (feat_out_ready),
        .ret_out    (feat_ret_out),
        .ema_out    (feat_ema_out)
    );

    // Signal generation: (return, EMA) -> signal
    signal_engine u_signal_engine (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_valid   (sig_in_valid),
        .in_ready   (sig_in_ready),
        .ret_in     (sig_ret_in),
        .ema_in     (sig_ema_in),
        .out_valid  (sig_out_valid),
        .out_ready  (sig_out_ready),
        .signal_out (sig_signal_out)
    );

    // Risk management: (position, beta) -> (allow_trade, kill_switch)
    risk_engine u_risk_engine (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_valid    (risk_in_valid),
        .in_ready    (risk_in_ready),
        .position_in (risk_position_in),
        .beta_in     (risk_beta_in),
        .out_valid   (risk_out_valid),
        .out_ready   (risk_out_ready),
        .allow_trade (risk_allow_trade),
        .kill_switch (risk_kill_switch)
    );

endmodule
