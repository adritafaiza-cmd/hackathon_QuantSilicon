module top (
    input  logic clk,
    input  logic rst_n,

    input  logic in_valid,
    output logic in_ready,
    input  logic signed [31:0] in_data,   // market input Q16.16

    output logic out_valid,
    input  logic out_ready,
    output logic signed [31:0] out_data   // final signal Q16.16
);

endmodule
