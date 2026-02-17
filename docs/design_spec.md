# QuantSilicon Design Spec (Phase 1)

## Fixed-Point Format
- All data signals are signed Q16.16 in 32-bit two's complement.
- Multiplication uses a 64-bit intermediate.
- After multiply, scale back with arithmetic shift right by 16:
  result_q16_16 = (a * b) >>> 16

## Ready/Valid Handshake
- Input transfer occurs when: in_valid && in_ready
- Output transfer occurs when: out_valid && out_ready
- If out_valid=1 and out_ready=0, out_data must remain stable until consumed.
- Avoid combinational loops between ready/valid.
