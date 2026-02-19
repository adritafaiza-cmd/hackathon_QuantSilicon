module top (
    input  logic clk,
    input  logic rst_n,

    input  logic in_valid,
    output logic in_ready,
    input  logic signed [31:0] in_data,   // Q16.16

    output logic out_valid,
    input  logic out_ready,
    output logic signed [31:0] out_data   // Q16.16
);

    // Inter-stage signals
    logic fe_valid, fe_ready;
    logic signed [31:0] fe_ret;
    logic signed [31:0] fe_ema;

    logic se_valid, se_ready;
    logic signed [31:0] se_signal;

    // Feature Engine
    feature_engine u_feature_engine (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .price_in (in_data),
        .out_valid(fe_valid),
        .out_ready(fe_ready),
        .ret_out  (fe_ret),
        .ema_out  (fe_ema)
    );

    // Signal Engine
    signal_engine u_signal_engine (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (fe_valid),
        .in_ready (fe_ready),
        .ret_in   (fe_ret),
        .ema_in   (fe_ema),
        .out_valid(se_valid),
        .out_ready(se_ready),
        .signal_out(se_signal)
    );

    // Risk Engine
    // Note: risk_engine expects position_in and beta_in, but we only have signal_out from signal_engine
    // Using signal as position, and tying beta to a constant (1.0 in Q16.16 = 32'h00010000)
    risk_engine u_risk_engine (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_valid   (se_valid),
        .in_ready   (se_ready),
        .position_in(se_signal),
        .beta_in    (32'h00010000),  // Q16.16 value of 1.0
        .out_valid  (out_valid),
        .out_ready  (out_ready),
        .allow_trade(out_data[0]),   // Map allow_trade to LSB of out_data
        .kill_switch()               // Unconnected for now
    );

endmodule
