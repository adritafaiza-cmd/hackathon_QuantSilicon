`timescale 1ns/1ps

module top_tb;

    logic clk;
    logic rst_n;

    logic in_valid;
    logic in_ready;
    logic signed [31:0] in_data;

    logic out_valid;
    logic out_ready;
    logic signed [31:0] out_data;

    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        in_valid = 0;
        in_data = 0;
        out_ready = 1;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);
        in_valid = 1;
        in_data = 32'sh0001_0000; // 1.0
        @(posedge clk);

        in_valid = 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule
