# Optimization Log

## Project
**QuantSilicon V1 — Streaming Quant Trading Pipeline**  
Modules:
- `feature_engine.sv`
- `signal_engine.sv`
- `risk_engine.sv`
- `quantsilicon_top.sv`

---

## Objective

Track architecture, logic, and performance optimizations introduced during development of the QuantSilicon RTL pipeline.

Focus areas:
- Streaming handshake correctness
- Pipeline stability
- Fixed-point arithmetic consistency (Q16.16)
- Backpressure handling
- Resource-aware design choices

---

## Optimization Timeline

---

### Optimization #1 — Standardized Q16.16 Fixed-Point Arithmetic

**Problem**

Initial modules used ad-hoc arithmetic operations which risked scaling mismatches across module boundaries.

**Change**

Created centralized package: `rtl/fxp_pkg.sv`

Added:
- `FXP_FRAC` — shared fractional width constant
- `fxp_mul_q16()` — safe Q16.16 multiply with 64-bit intermediate
- `fxp_abs()` — signed absolute value helper
- Shared constants (`W1`, `W2`, `LIMIT`)

**Result**
- Eliminated arithmetic inconsistencies across modules
- Improved readability and maintainability
- Easier cross-module verification

---

### Optimization #2 — Feature Engine Streaming Behavior

**Problem**

Potential output overwrite when downstream module stalled — no mechanism to hold output stable under backpressure.

**Change**

Implemented:
- Single-output register buffering
- Proper `valid`/`ready` handshake logic

Key behavior:
- Output held stable until consumed by downstream
- Input accepted only when output register is safe to overwrite

**Result**
- Fully backpressure-safe behavior
- Deterministic output timing regardless of downstream stall

---

### Optimization #3 — Signal Engine Arithmetic Simplification

**Problem**

Signal computation initially used intermediate temporary registers, causing unnecessary combinational logic depth.

**Change**

Converted to direct combinational expression using fixed-point helpers:

```systemverilog
signal = fxp_mul_q16(W1, ret) + fxp_mul_q16(W2, ema);
```

**Result**
- Reduced combinational depth on the signal path
- Cleaner synthesis path
- Easier timing closure

---

### Optimization #4 — Risk Engine Safety Logic

**Problem**

Risk checks required stable evaluation regardless of pipeline stalls. Unstable control signals could cause false kill-switch assertions.

**Change**
- Added absolute position computation using `fxp_abs`
- Explicit exposure comparison against `LIMIT`
- Registered outputs for deterministic control signal stability

```systemverilog
expo     = fxp_mul_q16(fxp_abs(position), beta);
kill_switch = (expo > LIMIT) ? 1'b1 : 1'b0;
allow_trade = ~kill_switch;
```

**Result**
- Stable kill-switch behavior under all flow conditions
- Predictable, glitch-free risk gating

---

### Optimization #5 — Top-Level Branch Synchronization

**Problem**

The Feature + Signal path and the Risk path have different internal latencies. Without synchronization, outputs from the two branches could become misaligned — pairing a signal from sample N with a risk decision from sample N-1.

**Change**

Implemented:
- Independent single-entry buffers per branch (Signal Buffer, Risk Buffer)
- Output valid asserted only when **both** branches are ready

```systemverilog
assign out_valid = signal_buf_valid && risk_buf_valid;
```

**Result**
- Guaranteed alignment of signal and risk decisions
- No stale or mismatched output pairs

---

### Optimization #6 — Backpressure Robustness

**Problem**

Output stalls (downstream `ready=0`) could cause buffer overwrite and data loss.

**Change**

Added pop-based buffer clear logic — buffers only dequeue on a successful downstream consume:

```systemverilog
assign pop = out_valid && out_ready;
```

Buffers hold their value until `pop` fires.

**Result**
- Stable output under arbitrary downstream stalls
- Correct AXI-style streaming semantics enforced end-to-end

---

## Verification Notes

- Handshake correctness stress-tested with artificial backpressure injection via `top_tb.sv`
- Randomized input streams validated against Python golden model (`golden_model.py`)
- Pipeline confirmed stable under sustained output stalls
- Full system-level verification handled by integration team

---

## Resource Awareness

Design decisions intentionally chosen for hardware efficiency:

| Decision | Hardware Benefit |
|---|---|
| Single-entry buffers (not FIFOs) | Minimal LUT and FF cost |
| Shift-based EMA (`ALPHA_SHIFT`) | Eliminates multiplier on feature path |
| Shared `fxp_pkg.sv` utilities | Prevents logic duplication across modules |
| Minimal state per module | Simplifies synthesis and P&R |

---

## Future Optimization Opportunities

### 1. Pipeline Latency Balancing
Replace buffer-based synchronization with explicit latency alignment registers for more predictable timing behavior.

### 2. DSP Slice Mapping
Annotate fixed-point multipliers with synthesis attributes to target FPGA DSP slices directly:
```systemverilog
(* use_dsp = "yes" *) wire signed [63:0] product;
```

### 3. Parameterization
Expose key constants as module-level parameters for flexibility:
- EMA alpha (`ALPHA_SHIFT`)
- Signal weights (`W1`, `W2`)
- Risk limit (`LIMIT`)

### 4. Formal Verification
Add SystemVerilog assertions (`SVA`) covering:
- Handshake correctness (no valid without ready on same cycle)
- Output stability under backpressure
- No dropped transactions across buffers

---

## Summary

The QuantSilicon pipeline after all optimizations supports:

- ✅ Streaming operation with AXI-style handshake
- ✅ Backpressure safety end-to-end
- ✅ Deterministic signal + risk output alignment
- ✅ Q16.16 fixed-point consistency across all modules
- ✅ Hardware-efficient, synthesis-friendly structure

---

*QuantSilicon V1 — CogniChip Hackathon (LLM4ChipDesign)*
