# QuantSilicon v2 – Design Specification

---

## 1. Numeric Representation

All signals use signed **Q16.16 fixed-point format**.

- Total width: 32 bits
- Integer bits: 16
- Fraction bits: 16
- Scaling factor: 2^16 = 65536

### Conversion

```text
real_to_fxp(x) = round(x × 65536)
fxp_to_real(v) = v / 65536
```

### Multiplication Rule

```text
Q16.16 × Q16.16 → Q32.32
result = (a * b) >>> 16
```

All right shifts must be arithmetic shifts (`>>>`).

---

## 2. Inputs (Per Tick)

All inputs are signed Q16.16.

```text
price[t]
position[t]
beta[t]
```

---

## 3. Internal State Registers

All signed Q16.16 unless specified.

```text
prev_price
ema_fast
ema_slow
mu
var
pos_ema
```

---

## 4. Feature Computation

### 4.1 Return

```text
ret[t] = price[t] - prev_price
prev_price_next = price[t]
```

---

### 4.2 Dual EMA Trend

```text
ema_fast_next = ema_fast + ((ret[t] - ema_fast) >>> AF)
ema_slow_next = ema_slow + ((ret[t] - ema_slow) >>> AS)
trend[t] = ema_fast_next - ema_slow_next
```

Constants:

```text
AF = 3   (alpha_fast = 1/8)
AS = 6   (alpha_slow = 1/64)
```

---

### 4.3 EWMA Mean of Returns

```text
mu_next = mu + ((ret[t] - mu) >>> AM)
demean[t] = ret[t] - mu_next
```

Constant:

```text
AM = 5   (alpha_mean = 1/32)
```

---

### 4.4 EWMA Variance

```text
var_next = var + (((demean[t] * demean[t]) >>> 16 - var) >>> AV)
```

Constant:

```text
AV = 5   (alpha_var = 1/32)
```

Volatility approximation:

```text
vol[t] ≈ sqrt(var_next)
inv_vol[t] ≈ 1 / (vol[t] + eps)
```

---

## 5. Signal Model

### 5.1 Z-Score

```text
zscore[t] = (demean[t] * inv_vol[t]) >>> 16
```

### 5.2 Raw Multi-Factor Signal

```text
signal_raw[t] =
    ((trend[t] * wT) >>> 16)
  - ((zscore[t] * wZ) >>> 16)
```

### 5.3 Volatility-Scaled Signal

```text
signal[t] = (signal_raw[t] * inv_vol[t]) >>> 16
```

---

## 6. Risk Model

### 6.1 Smoothed Position

```text
pos_ema_next = pos_ema + ((position[t] - pos_ema) >>> AP)
```

Constant:

```text
AP = 4   (alpha_pos = 1/16)
```

---

### 6.2 Beta-Weighted Exposure

```text
abs_pos = (pos_ema_next < 0) ? -pos_ema_next : pos_ema_next
expo_beta[t] = (abs_pos * beta[t]) >>> 16
```

---

### 6.3 Volatility-Adjusted Exposure

```text
expo_risk[t] =
    (expo_beta[t] * (1 + ((kV * vol[t]) >>> 16))) >>> 16
```

---

### 6.4 Kill Condition

```text
if expo_risk[t] > LIMIT:
    kill_switch = 1
    allow_trade = 0
    signal_out = 0
else:
    kill_switch = 0
    allow_trade = 1
    signal_out = signal[t]
```

---

## 7. Frozen Constants (Q16.16)

```text
wT = 0.75   → 49152
wZ = 0.25   → 16384
kV = 0.50   → 32768
LIMIT = 2.0 → 131072
eps = 0.01  → 655
```

---

## 8. Interface Protocol

Streaming ready/valid handshake.

```text
Input accepted when:
in_valid && in_ready

Output consumed when:
out_valid && out_ready
```

Outputs per tick:

```text
signal_out (Q16.16)
allow_trade (1 bit)
kill_switch (1 bit)
```

---

## 9. Latency Target

```text
Deterministic bounded latency ≤ 5 cycles
Target throughput: 1 sample per cycle (if pipelined)
```

---




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
