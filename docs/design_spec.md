# QuantSilicon V1 — Design Specification

## 1. Overview

QuantSilicon is a streaming hardware pipeline designed to accelerate lightweight quantitative trading signal generation and risk evaluation using fixed-point arithmetic.

The system processes market data tick-by-tick and produces:

- Trading signal (Q16.16 fixed-point)
- Risk decision outputs:
  - `allow_trade`
  - `kill_switch`

The design targets low-latency execution and deterministic behavior suitable for hardware deployment.

---

## 2. Design Goals

### Primary Objectives
- Deterministic low-latency streaming pipeline
- Fixed-point arithmetic for hardware efficiency
- Modular RTL blocks with clear interfaces
- Backpressure-safe ready/valid handshaking
- Risk-aware signal generation

### Constraints
- Q16.16 fixed-point format
- Streaming architecture (no large buffers)
- Synthesizable RTL
- Simple verification-friendly logic

---

## 3. System Architecture

Pipeline structure:

Input Stream
│
▼
Feature Engine
(ret, EMA extraction)
│
▼
Signal Engine
(weighted signal generation)
│
▼
Output Alignment
▲
│
Risk Engine
(exposure + kill logic)

### Data Flow

Input tick provides:

- `price`
- `position`
- `beta`

Two parallel branches operate:

1. **Signal Branch**
   - Feature extraction
   - Signal computation

2. **Risk Branch**
   - Exposure computation
   - Risk decision

Outputs are aligned before being emitted.

---

## 4. Mathematical Model (V1)

### Inputs (per tick)
- `price` (Q16.16)
- `position` (Q16.16)
- `beta` (Q16.16)

### Feature Extraction

ret = price - prev_price
ema = ema + ((ret - ema) >> ALPHA_SHIFT)

Where:

ALPHA_SHIFT = 5  (alpha = 1/32)

---

### Signal Model

signal = w1 * ret + w2 * ema

Constants (Q16.16):

| Parameter | Real | Fixed |
|---|---|---|
| w1 | 0.75 | 49152 |
| w2 | 0.25 | 16384 |

Multiplication uses:

fxp_mul_q16(a,b)

---

### Risk Model

Exposure:

expo = abs(position) * beta

Decision:

if expo > LIMIT:
kill_switch = 1
allow_trade = 0
else:
kill_switch = 0
allow_trade = 1

Risk threshold:

LIMIT = 2.0  → 131072 (Q16.16)

---

## 5. Fixed-Point Representation

QuantSilicon uses **Q16.16 signed fixed-point**.

Conversion:

X_fixed = round(X_real * 65536)
X_real  = X_fixed / 65536

### Rationale
- Avoid floating-point hardware cost
- Deterministic arithmetic
- Easy scaling and verification

---

## 6. Streaming Interface Specification

All modules follow ready/valid protocol.

### Input Stream

| Signal | Description |
|---|---|
| in_valid | Input sample valid |
| in_ready | Module ready to accept |
| price | Price input |
| position | Position input |
| beta | Beta input |

### Output Stream

| Signal | Description |
|---|---|
| out_valid | Output data valid |
| out_ready | Consumer ready |
| signal_out | Trading signal |
| allow_trade | Risk permission |
| kill_switch | Risk shutdown |

### Handshake Contract

Transfer occurs when:
valid && ready == 1

---

## 7. Module Breakdown

### 7.1 Feature Engine
Responsibilities:
- Compute return
- Compute EMA
- Maintain state (prev_price, ema)

Outputs:
- `ret`
- `ema`

---

### 7.2 Signal Engine
Responsibilities:
- Weighted fixed-point multiply
- Signal accumulation

Formula:

signal = w1ret + w2ema

---

### 7.3 Risk Engine
Responsibilities:
- Compute exposure
- Compare against limit
- Generate kill logic

---

### 7.4 Top-Level Integration
Responsibilities:
- Align parallel branches
- Buffer outputs
- Maintain handshake correctness
- Prevent deadlock under backpressure

---

## 8. Latency Target

Target latency:

≤ 5 cycles (pipeline steady state)

Actual latency depends on:
- buffering
- backpressure events
- pipeline depth

---

## 9. AI-Assisted Design Workflow

This project uses AI-assisted RTL generation via CogniChip and LLM-based design iteration.

AI usage included:

- RTL skeleton generation
- Interface drafting
- Fixed-point utility generation
- Design iteration and refinement

All generated RTL was manually reviewed for:
- handshake correctness
- fixed-point scaling safety
- synthesizability

---

## 10. Future Improvements (V2)

Potential extensions:

- Volatility-aware weighting
- Adaptive alpha (dynamic EMA)
- Multi-asset pipeline
- Hardware risk aggregation
- Parallel signal lanes

---

## 11. Summary

QuantSilicon V1 demonstrates a complete streaming quant pipeline in synthesizable RTL combining:

- Signal generation
- Risk management
- Fixed-point arithmetic
- AI-assisted hardware development
