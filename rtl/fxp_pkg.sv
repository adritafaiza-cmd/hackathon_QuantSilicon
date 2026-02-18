// rtl/fxp_pkg.sv

package fxp_pkg;

  // =============================
  // Fixed-Point Configuration
  // =============================

  // Fractional bits (Q16.16)
  localparam int FXP_FRAC = 16;

  // =============================
  // EMA Configuration
  // =============================

  localparam int ALPHA_SHIFT = 5;  // alpha = 1/32

  // =============================
  // Signal Weights (Q16.16)
  // =============================

  localparam logic signed [31:0] W1 = 32'sd49152;   // 0.75
  localparam logic signed [31:0] W2 = 32'sd16384;   // 0.25

  // =============================
  // Risk Limit (Q16.16)
  // =============================

  localparam logic signed [31:0] LIMIT = 32'sd131072; // 2.0

  // =============================
  // Utility Functions
  // =============================

  // Absolute value
  function automatic logic signed [31:0] fxp_abs(
      input logic signed [31:0] x
  );
    fxp_abs = (x < 0) ? -x : x;
  endfunction

  // Q16.16 multiply
  function automatic logic signed [31:0] fxp_mul_q16(
      input logic signed [31:0] a,
      input logic signed [31:0] b
  );
    logic signed [63:0] product;
    begin
      product = $signed(a) * $signed(b);
      fxp_mul_q16 = product >>> FXP_FRAC;
    end
  endfunction

endpackage
