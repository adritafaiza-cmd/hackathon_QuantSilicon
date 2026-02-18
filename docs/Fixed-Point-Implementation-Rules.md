## Fixed-Point Implementation Rules (Q16.16)

All values are signed Q16.16 stored as 32-bit signed integers.

Conversion:
- X_fixed = round(X * 65536)
- X_real = X_fixed / 65536

Multiplication:
- If a and b are Q16.16, compute 64-bit product p = a*b (Q32.32)
- Rescale back to Q16.16 using:
  p_q16 = p >>> 16

Absolute value:
- abs(x) = (x < 0) ? -x : x

Frozen constants (Q16.16 integers):
- wT = 49152
- wZ = 16384
- kV = 32768
- LIMIT = 131072
- eps = 655
