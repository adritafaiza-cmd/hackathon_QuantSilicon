// rtl/fxp_pkg.sv
package fxp_pkg;

  // Q16.16 scaling
  localparam int FXP_FRAC = 16;

  // Common constants in Q16.16
  localparam logic signed [31:0] WT    = 32'sd49152;   // 0.75
  localparam logic signed [31:0] WZ    = 32'sd16384;   // 0.25
  localparam logic signed [31:0] KV    = 32'sd32768;   // 0.50
  localparam logic signed [31:0] LIMIT = 32'sd131072;  // 2.0
  localparam logic signed [31:0] EPS   = 32'sd655;     // 0.01

  // Absolute value (Q16.16)
  function automatic logic signed [31:0] fxp_abs(input logic signed [31:0] x);
    fxp_abs = (x < 0) ? -x : x;
  endfunction

  // Multiply two Q16.16 numbers -> Q16.16 result
  function automatic logic signed [31:0] fxp_mul_q16(
      input logic signed [31:0] a,
      input logic signed [31:0] b
  );
    logic signed [63:0] p;
    begin
      p = $signed(a) * $signed(b);      // Q32.32
      fxp_mul_q16 = $signed(p >>> FXP_FRAC); // back to Q16.16
    end
  endfunction

endpackage
