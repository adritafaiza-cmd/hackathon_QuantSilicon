# QuantSilicon 🚀
### AI-Assisted Hardware Pipeline for Quantitative Trading Signals

QuantSilicon is a streaming RTL-based hardware system that generates quantitative trading signals while enforcing real-time risk management using fixed-point arithmetic.

Built as part of the **CogniChip Hackathon (LLM4ChipDesign)**, the project explores how AI-assisted chip design workflows can accelerate development of practical hardware systems for quantitative finance.

---

## 🎯 Project Motivation

Modern trading systems rely on fast signal computation and strict risk controls. Most implementations run purely in software, introducing latency and nondeterministic execution.

QuantSilicon explores:

- Low-latency signal generation in hardware
- Deterministic risk enforcement
- AI-assisted RTL development using CogniChip
- Translating quant models into synthesizable silicon logic

---

## 📁 Repository Structure

```
QuantSilicon/
│
├── README.md
├── Makefile
│
├── docs/
│   ├── design_spec.md
│   ├── architecture_diagram.png
│   └── ai_optimization_log.md
│
├── rtl/
│   ├── fxp_pkg.sv
│   ├── feature_engine.sv
│   ├── signal_engine.sv
│   ├── risk_engine.sv
│   └── quantsilicon_top.sv
│
├── tb/
│   └── top_tb.sv
│
└── python_model/
    ├── golden_model.py
    └── generate_test_data.py
```

---

## 🧠 High-Level Architecture

```
Input Stream (price, position, beta)
│
▼
Feature Engine
(return + EMA extraction)
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
(exposure + kill-switch)
```

### Pipeline Characteristics

- Streaming ready/valid interfaces
- Fixed-point Q16.16 arithmetic
- Parallel signal + risk branches
- Backpressure-safe design
- Modular RTL blocks

---

## ⚙️ Mathematical Model (V1)

### Feature Extraction

```
ret = price - prev_price
ema = ema + ((ret - ema) >> ALPHA_SHIFT)
```

`ALPHA_SHIFT = 5` (alpha = 1/32)

### Signal Generation

```
signal = w1 * ret + w2 * ema
```

Constants (Q16.16):

| Parameter | Real Value | Fixed-Point |
|-----------|-----------|-------------|
| w1        | 0.75      | 49152       |
| w2        | 0.25      | 16384       |

### Risk Model

```
expo = abs(position) * beta

if expo > LIMIT:
    kill_switch = 1
    allow_trade = 0
```

`LIMIT = 2.0` (Q16.16 → 131072)

---

## 🔢 Fixed-Point Format (Q16.16)

All arithmetic uses signed Q16.16 fixed-point:

```
X_fixed = round(X_real * 65536)
X_real  = X_fixed / 65536
```

Benefits:
- Deterministic hardware behavior
- Lower resource cost vs floating point
- Easier synthesis and timing closure

---

## 🧩 Module Overview

### Feature Engine
- Computes return (price delta)
- Computes EMA smoothing
- Maintains internal state

### Signal Engine
- Weighted fixed-point multiplications
- Generates final trading signal

### Risk Engine
- Exposure calculation
- Kill-switch decision logic

### Top-Level Integration
- Synchronizes parallel branches
- Handles buffering and handshake alignment
- Produces final output stream

---

## 🔄 Streaming Interface (Ready / Valid)

All modules follow AXI-style handshake:

```
Transfer occurs when: valid && ready == 1
```

### Input Signals
| Signal | Description |
|--------|-------------|
| `in_valid` | Input data valid |
| `in_ready` | Downstream ready |
| `price` | Asset price |
| `position` | Current position |
| `beta` | Risk factor |

### Output Signals
| Signal | Description |
|--------|-------------|
| `out_valid` | Output data valid |
| `out_ready` | Consumer ready |
| `signal_out` | Trading signal |
| `allow_trade` | Trade permission flag |
| `kill_switch` | Risk breach flag |

---

## 🧪 Build & Simulation

**Compile:**

```bash
iverilog -g2012 -o sim_top.out \
  rtl/fxp_pkg.sv \
  rtl/feature_engine.sv \
  rtl/signal_engine.sv \
  rtl/risk_engine.sv \
  rtl/quantsilicon_top.sv \
  tb/top_tb.sv
```

**Run:**

```bash
vvp sim_top.out
```

**Waveforms:**

```bash
gtkwave top.vcd
```

---

## 🤖 AI-Assisted Development (CogniChip)

This project intentionally explores AI-driven hardware workflows.

AI was used for:
- RTL scaffolding
- Interface drafting
- Fixed-point utility generation
- Iterative design refinement

All AI-generated logic was manually validated for:
- Handshake correctness
- Fixed-point scaling
- Synthesizability
- Architectural consistency

---

## 🧑‍💻 Team Roles

**Chintan — Chief Architect & Quant Engineer**
- System architecture
- Quant model definition
- Fixed-point specification
- Pipeline integration

**Faiza — Verification & Testing**
- Testbench development
- Simulation validation
- Backpressure testing
- Output correctness checks

**Akhash — RTL Development & Optimization**
- Module implementation
- Timing-aware RTL
- Interface integration
- Cleanup and synthesis prep

---

## ⏱️ Performance Target

| Metric | Target |
|--------|--------|
| Pipeline latency | ≤ 5 cycles (steady state) |
| Streaming throughput | 1 sample/cycle (ideal) |
| Risk enforcement | Deterministic |

---

## 🔮 Future Directions

- Adaptive volatility weighting
- Multi-asset processing lanes
- Hardware portfolio-level risk aggregation
- FPGA deployment
- AI-guided architecture search

---

## 🏁 Summary

QuantSilicon demonstrates how AI-assisted chip design can rapidly produce a complete hardware trading pipeline combining:
- Quantitative signal generation
- Real-time risk management
- Fixed-point hardware arithmetic
- Modular streaming RTL design

This project serves as a bridge between quantitative finance workflows and hardware acceleration.
