// risk_engine.sv
// Risk management module with Q16.16 fixed-point arithmetic
// Monitors position exposure and generates trading control signals

import fxp_pkg::*;

module risk_engine (
    input  logic                clk,
    input  logic                rst_n,
    
    // Input stream interface
    input  logic                in_valid,
    output logic                in_ready,
    input  logic signed [31:0]  position_in, // Q16.16
    input  logic signed [31:0]  beta_in,     // Q16.16
    
    // Output stream interface
    output logic                out_valid,
    input  logic                out_ready,
    output logic                allow_trade,
    output logic                kill_switch
);

    // Output registers
    logic allow_trade_reg;
    logic kill_switch_reg;
    
    // Intermediate computation signals
    logic signed [31:0] abs_pos;
    logic signed [31:0] expo;
    logic allow_trade_next;
    logic kill_switch_next;
    
    // Handshake control signals
    logic accept_input;
    logic consume_output;
    
    // Handshake logic
    assign consume_output = out_valid && out_ready;
    assign accept_input = in_valid && in_ready;
    
    // Ready when output buffer is empty or being consumed
    assign in_ready = ~out_valid || consume_output;
    
    // Combinational computation using fxp_abs and fxp_mul_q16
    assign abs_pos = fxp_abs(position_in);
    assign expo = fxp_mul_q16(abs_pos, beta_in);
    
    // Risk evaluation logic
    assign kill_switch_next = (expo > LIMIT) ? 1'b1 : 1'b0;
    assign allow_trade_next = (expo > LIMIT) ? 1'b0 : 1'b1;
    
    // Output assignments
    assign allow_trade = allow_trade_reg;
    assign kill_switch = kill_switch_reg;
    
    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allow_trade_reg <= 1'b0;
            kill_switch_reg <= 1'b0;
            out_valid       <= 1'b0;
        end else begin
            // Handle output valid flag
            if (consume_output && !accept_input) begin
                // Output consumed, no new input
                out_valid <= 1'b0;
            end else if (accept_input) begin
                // New input accepted, output will be valid
                out_valid <= 1'b1;
            end
            
            // Accept new input and update output registers
            if (accept_input) begin
                allow_trade_reg <= allow_trade_next;
                kill_switch_reg <= kill_switch_next;
            end
        end
    end

endmodule
