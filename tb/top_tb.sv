// top_tb.sv
// Testbench for quantsilicon_top module
// Tests streaming pipeline with handshaking and backpressure

`timescale 1ns/1ps

module top_tb;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    logic clk;
    logic rst_n;
    
    // =========================================================================
    // DUT Signals
    // =========================================================================
    logic                in_valid;
    logic                in_ready;
    logic signed [31:0]  price;
    logic signed [31:0]  position;
    logic signed [31:0]  beta;
    logic                out_valid;
    logic                out_ready;
    logic signed [31:0]  signal_out;
    logic                allow_trade;
    logic                kill_switch;
    
    // =========================================================================
    // Test Control Variables
    // =========================================================================
    int sample_count;
    int output_count;
    logic signed [31:0] price_current;
    logic signed [31:0] position_current;
    logic signed [31:0] beta_constant;
    logic signed [31:0] price_delta;
    
    // For verifying output stability during backpressure
    logic signed [31:0] signal_snapshot;
    logic allow_snapshot;
    logic kill_snapshot;
    logic snapshot_taken;
    
    // =========================================================================
    // Clock Generation (10ns period)
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    quantsilicon_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_valid    (in_valid),
        .in_ready    (in_ready),
        .price       (price),
        .position    (position),
        .beta        (beta),
        .out_valid   (out_valid),
        .out_ready   (out_ready),
        .signal_out  (signal_out),
        .allow_trade (allow_trade),
        .kill_switch (kill_switch)
    );
    
    // =========================================================================
    // Q16.16 Conversion Helper Function
    // =========================================================================
    function logic signed [31:0] to_q16(real value);
        return $rtoi(value * 65536.0);
    endfunction
    
    function real from_q16(logic signed [31:0] value);
        return $itor(value) / 65536.0;
    endfunction
    
    // =========================================================================
    // Output Monitor
    // =========================================================================
    always @(posedge clk) begin
        if (out_valid && out_ready) begin
            $display("LOG: %0t : INFO : top_tb : dut.signal_out : expected_value: N/A actual_value: %f", 
                     $time, from_q16(signal_out));
            $display("OUTPUT [%0d]: price=%f pos=%f signal=%f allow=%0d kill=%0d", 
                     output_count,
                     from_q16(price_current),
                     from_q16(position_current),
                     from_q16(signal_out),
                     allow_trade,
                     kill_switch);
            output_count++;
        end
    end
    
    // =========================================================================
    // Backpressure Stability Checker
    // =========================================================================
    always @(posedge clk) begin
        if (out_valid && !out_ready) begin
            if (!snapshot_taken) begin
                // Take snapshot on first cycle of backpressure
                signal_snapshot = signal_out;
                allow_snapshot = allow_trade;
                kill_snapshot = kill_switch;
                snapshot_taken = 1'b1;
                $display("LOG: %0t : INFO : top_tb : backpressure_start : expected_value: stable actual_value: monitoring", $time);
            end else begin
                // Verify outputs remain stable
                if (signal_out !== signal_snapshot) begin
                    $display("LOG: %0t : ERROR : top_tb : dut.signal_out : expected_value: %f actual_value: %f", 
                             $time, from_q16(signal_snapshot), from_q16(signal_out));
                    $error("Signal changed during backpressure!");
                end
                if (allow_trade !== allow_snapshot) begin
                    $display("LOG: %0t : ERROR : top_tb : dut.allow_trade : expected_value: %0d actual_value: %0d", 
                             $time, allow_snapshot, allow_trade);
                    $error("allow_trade changed during backpressure!");
                end
                if (kill_switch !== kill_snapshot) begin
                    $display("LOG: %0t : ERROR : top_tb : dut.kill_switch : expected_value: %0d actual_value: %0d", 
                             $time, kill_snapshot, kill_switch);
                    $error("kill_switch changed during backpressure!");
                end
            end
        end else if (out_valid && out_ready && snapshot_taken) begin
            // Reset snapshot when outputs consumed
            snapshot_taken = 1'b0;
            $display("LOG: %0t : INFO : top_tb : backpressure_end : expected_value: released actual_value: consumed", $time);
        end
    end
    
    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        $display("TEST START");
        
        // Initialize signals
        rst_n = 0;
        in_valid = 0;
        out_ready = 1;
        price = 0;
        position = 0;
        beta = 0;
        sample_count = 0;
        output_count = 0;
        snapshot_taken = 0;
        
        // Initialize test variables
        // Price starts at 100.0 in Q16.16
        price_current = to_q16(100.0);
        // Beta constant at 1.2
        beta_constant = to_q16(1.2);
        
        // Apply reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        $display("Starting input sequence - 20 samples");
        
        // Drive 20 input samples
        for (int i = 0; i < 20; i++) begin
            // Calculate position ramping from 0.0 to 3.0
            position_current = to_q16(i * 3.0 / 19.0);
            
            // Generate random walk for price (±0.5 per step)
            price_delta = $random % 32768; // Random value ±0.5 in Q16.16
            if ($random % 2) begin
                price_current = price_current + price_delta;
            end else begin
                price_current = price_current - price_delta;
            end
            
            // Prepare inputs
            price = price_current;
            position = position_current;
            beta = beta_constant;
            in_valid = 1;
            
            // Wait for in_ready (respect handshake)
            wait(in_ready);
            @(posedge clk);
            in_valid = 0;
            
            sample_count++;
            $display("INPUT [%0d]: price=%f pos=%f beta=%f", 
                     i, from_q16(price), from_q16(position), from_q16(beta));
            
            // Apply backpressure mid-run (samples 8-11)
            if (i == 8) begin
                $display("Applying backpressure for 4 cycles...");
                out_ready = 0;
                repeat(4) @(posedge clk);
                out_ready = 1;
                $display("Backpressure released");
            end
            
            // Longer delay between samples to allow pipeline drainage
            repeat(5) @(posedge clk);
        end
        
        $display("All inputs driven, waiting for outputs...");
        
        // Wait for all outputs to be consumed (longer wait for pipeline drainage)
        repeat(500) @(posedge clk);
        
        // Check if we got all outputs
        if (output_count == 20) begin
            $display("TEST PASSED");
            $display("Successfully processed all 20 samples");
        end else begin
            $display("ERROR");
            $error("Expected 20 outputs, got %0d", output_count);
            $display("TEST FAILED");
        end
        
        $finish;
    end
    
    // =========================================================================
    // Timeout Watchdog
    // =========================================================================
    initial begin
        #50000; // 50us timeout
        $display("ERROR");
        $error("Simulation timeout!");
        $display("TEST FAILED");
        $finish;
    end
    
    // =========================================================================
    // Waveform Dump
    // =========================================================================
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule
