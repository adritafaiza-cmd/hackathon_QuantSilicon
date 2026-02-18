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
    logic signed [31:0] fe_data;

    logic se_valid, se_ready;
    logic signed [31:0] se_data;

    // Feature Engine
    feature_engine u_feature_engine (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .in_data  (in_data),
        .out_valid(fe_valid),
        .out_ready(fe_ready),
        .out_data (fe_data)
    );

    // Signal Engine
    signal_engine u_signal_engine (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (fe_valid),
        .in_ready (fe_ready),
        .in_data  (fe_data),
        .out_valid(se_valid),
        .out_ready(se_ready),
        .out_data (se_data)
    );

    // Risk Engine
    risk_engine u_risk_engine (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (se_valid),
        .in_ready (se_ready),
        .in_data  (se_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data (out_data)
    );

endmodule
