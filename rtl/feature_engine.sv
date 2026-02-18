// feature_engine.sv
// Streaming feature extraction module with Q16.16 fixed-point arithmetic
// Computes return (price difference) and exponential moving average (EMA)

import fxp_pkg::*;

module feature_engine (
    input  logic                clk,
    input  logic                rst_n,
    
    // Input stream interface
    input  logic                in_valid,
    output logic                in_ready,
    input  logic signed [31:0]  price_in,    // Q16.16
    
    // Output stream interface
    output logic                out_valid,
    input  logic                out_ready,
    output logic signed [31:0]  ret_out,     // Q16.16
    output logic signed [31:0]  ema_out      // Q16.16
);

    // State registers
    logic signed [31:0] prev_price;
    logic signed [31:0] ema;
    logic signed [31:0] ret_reg;
    logic signed [31:0] ema_reg;
    
    // Intermediate computation signals
    logic signed [31:0] ret_next;
    logic signed [31:0] ema_delta;
    logic signed [31:0] ema_next;
    
    // Handshake control signals
    logic accept_input;
    logic consume_output;
    
    // Handshake logic
    assign consume_output = out_valid && out_ready;
    assign accept_input = in_valid && in_ready;
    
    // Ready when output buffer is empty or being consumed
    assign in_ready = ~out_valid || consume_output;
    
    // Combinational computation
    assign ret_next = price_in - prev_price;
    assign ema_delta = ret_next - ema;
    assign ema_next = ema + (ema_delta >>> ALPHA_SHIFT);
    
    // Output assignments
    assign ret_out = ret_reg;
    assign ema_out = ema_reg;
    
    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_price  <= 32'sd0;
            ema         <= 32'sd0;
            ret_reg     <= 32'sd0;
            ema_reg     <= 32'sd0;
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
            
            // Accept new input and update state
            if (accept_input) begin
                // Update state variables
                prev_price <= price_in;
                ema <= ema_next;
                
                // Latch computed results to output registers
                ret_reg <= ret_next;
                ema_reg <= ema_next;
            end
        end
    end

endmodule
