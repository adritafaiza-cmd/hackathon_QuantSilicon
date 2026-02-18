// signal_engine.sv
// Signal generation module with Q16.16 fixed-point arithmetic
// Computes weighted combination of return and EMA features

import fxp_pkg::*;

module signal_engine (
    input  logic                clk,
    input  logic                rst_n,
    
    // Input stream interface
    input  logic                in_valid,
    output logic                in_ready,
    input  logic signed [31:0]  ret_in,      // Q16.16
    input  logic signed [31:0]  ema_in,      // Q16.16
    
    // Output stream interface
    output logic                out_valid,
    input  logic                out_ready,
    output logic signed [31:0]  signal_out   // Q16.16
);

    // Output register
    logic signed [31:0] signal_reg;
    
    // Intermediate computation signals
    logic signed [31:0] signal_next;
    logic signed [31:0] term1;
    logic signed [31:0] term2;
    
    // Handshake control signals
    logic accept_input;
    logic consume_output;
    
    // Handshake logic
    assign consume_output = out_valid && out_ready;
    assign accept_input = in_valid && in_ready;
    
    // Ready when output buffer is empty or being consumed
    assign in_ready = ~out_valid || consume_output;
    
    // Combinational computation using fxp_mul_q16
    assign term1 = fxp_mul_q16(ret_in, W1);
    assign term2 = fxp_mul_q16(ema_in, W2);
    assign signal_next = term1 + term2;
    
    // Output assignment
    assign signal_out = signal_reg;
    
    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_reg  <= 32'sd0;
            out_valid   <= 1'b0;
        end else begin
            // Handle output valid flag
            if (consume_output && !accept_input) begin
                // Output consumed, no new input
                out_valid <= 1'b0;
            end else if (accept_input) begin
                // New input accepted, output will be valid
                out_valid <= 1'b1;
            end
            
            // Accept new input and update output register
            if (accept_input) begin
                signal_reg <= signal_next;
            end
        end
    end

endmodule
