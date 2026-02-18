# QuantSilicon – Streaming Interface Contract (Task 4)

This document defines the ready/valid handshake protocol for QuantSilicon V1.

All AI-generated RTL must strictly follow this interface contract.

---

## 1. Ready/Valid Overview

QuantSilicon uses a streaming ready/valid handshake model.

A transaction is transferred only when both signals are asserted.

```
transfer occurs when:
in_valid && in_ready
```

and

```
out_valid && out_ready
```

---

## 2. Input Handshake Rules

A transaction is accepted when:

```
in_valid && in_ready
```

### Requirements

- Producer asserts `in_valid` when input data is valid.
- Consumer asserts `in_ready` when it can accept data.
- If `in_valid = 1` and `in_ready = 0`, input data must remain stable.
- Data must not change until handshake completes.
- No combinational feedback loops between valid and ready.

---

## 3. Output Handshake Rules

A transaction is consumed when:

```
out_valid && out_ready
```

### Requirements

- Module asserts `out_valid` when output data is valid.
- Downstream asserts `out_ready` when it can accept data.
- If `out_valid = 1` and `out_ready = 0`, output data must remain stable.
- Output signals must remain stable until consumed.
- No combinational loops allowed.

---

## 4. Top-Level Interface (quantsilicon_top)

### Inputs

```
clk
rst_n
in_valid
in_ready
price      (Q16.16 signed)
position   (Q16.16 signed)
beta       (Q16.16 signed)
```

### Outputs

```
out_valid
out_ready
signal_out   (Q16.16 signed)
allow_trade  (1 bit)
kill_switch  (1 bit)
```

---

## 5. V1 Implementation Policy (Scope Control)

To reduce complexity in V1:

- `in_ready` may be tied high unless output backpressure is implemented.
- Submodules must not introduce complex backpressure chains.
- Valid signals propagate forward cleanly.
- Output must remain stable while:
  ```
  out_valid = 1 && out_ready = 0
  ```
- Deterministic pipeline depth is allowed.

---

## 6. Latency & Throughput Targets

```
Latency: <= 5 cycles (deterministic)
Throughput target: 1 sample per cycle (if pipelined)
```

---

## 7. Enforcement Rules

All CogniChip-generated RTL must:

- Implement ready/valid exactly as specified
- Hold output stable until consumed
- Avoid combinational handshake loops
- Follow V1 simplification policy
- Use fxp_pkg for all constants and scaling

Any violation must be corrected via prompt refinement — not manual RTL editing.

---
