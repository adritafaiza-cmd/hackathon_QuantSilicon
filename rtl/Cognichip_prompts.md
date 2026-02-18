# QuantSilicon – CogniChip Prompt Log

This document records all AI prompts used to generate RTL modules for QuantSilicon V1.

All modules were generated using CogniChip under strict architectural constraints defined in:

- docs/design_spec.md
- docs/STREAMING_INTERFACE.md
- rtl/fxp_pkg.sv

---

# 1️⃣ feature_engine.sv Prompt

```
Generate synthesizable SystemVerilog module: feature_engine.sv

REQUIREMENTS:
- Use signed Q16.16 fixed-point (32-bit signed)
- Import fxp_pkg::*;
- Use ALPHA_SHIFT from fxp_pkg
- No real types
- No division operator '/'
- No manual >>>16 scaling
- Fully synthesizable
- Follow ready/valid handshake

Ports:

Inputs:
clk
rst_n
in_valid
out_ready
price_in (logic signed [31:0])

Outputs:
in_ready
out_valid
ret_out (logic signed [31:0])
ema_out (logic signed [31:0])

Behavior:
ret = price_in - prev_price
ema_next = ema + ((ret - ema) >>> ALPHA_SHIFT)

Handshake:
- accept input when in_valid && in_ready
- consume output when out_valid && out_ready
- in_ready = ~out_valid || (out_valid && out_ready)
- hold outputs stable when out_valid=1 && out_ready=0

Return only synthesizable SystemVerilog.
```

---

# 2️⃣ signal_engine.sv Prompt

```
Generate synthesizable SystemVerilog module: signal_engine.sv

Requirements:
- Import fxp_pkg::*;
- Signed Q16.16
- Use fxp_mul_q16() for multiplication
- Use W1 and W2 from fxp_pkg
- No real types
- No division operator
- No manual >>>16 scaling
- Fully synthesizable
- Follow ready/valid handshake

Ports:

Inputs:
clk
rst_n
in_valid
out_ready
ret_in  (logic signed [31:0])
ema_in  (logic signed [31:0])

Outputs:
in_ready
out_valid
signal_out (logic signed [31:0])

Behavior:
signal_next = fxp_mul_q16(ret_in, W1) + fxp_mul_q16(ema_in, W2)

Handshake:
- accept input when in_valid && in_ready
- consume output when out_valid && out_ready
- in_ready = ~out_valid || (out_valid && out_ready)
- hold output stable while out_valid=1 && out_ready=0

Return only the full SystemVerilog module.
```

---

# 3️⃣ risk_engine.sv Prompt

```
Generate synthesizable SystemVerilog module: risk_engine.sv

Requirements:
- Import fxp_pkg::*;
- Signed Q16.16
- Use fxp_abs() for absolute value
- Use fxp_mul_q16() for multiplication
- Use LIMIT from fxp_pkg
- No real types
- No division operator
- No manual >>>16 scaling
- Fully synthesizable
- Follow ready/valid handshake

Ports:

Inputs:
clk
rst_n
in_valid
out_ready
position_in (logic signed [31:0])
beta_in     (logic signed [31:0])

Outputs:
in_ready
out_valid
allow_trade
kill_switch

Behavior:
abs_pos = fxp_abs(position_in)
expo    = fxp_mul_q16(abs_pos, beta_in)

if expo > LIMIT:
  kill_switch = 1
  allow_trade = 0
else:
  kill_switch = 0
  allow_trade = 1

Handshake:
- accept input when in_valid && in_ready
- consume output when out_valid && out_ready
- in_ready = ~out_valid || (out_valid && out_ready)
- hold outputs stable while out_valid=1 && out_ready=0

Return only synthesizable SystemVerilog.
```

---

# 4️⃣ quantsilicon_top.sv Prompt

```
Generate synthesizable SystemVerilog module: quantsilicon_top.sv

Requirements:
- Import fxp_pkg::*;
- Signed Q16.16
- Fully synthesizable
- No real types
- No division
- Follow ready/valid handshake
- Deterministic behavior

Topology:
- Broadcast price to feature_engine
- Broadcast position & beta to risk_engine
- feature_engine -> signal_engine pipeline
- Combine outputs when both branches valid

Top-Level Ports:

Inputs:
clk
rst_n
in_valid
price
position
beta
out_ready

Outputs:
in_ready
out_valid
signal_out
allow_trade
kill_switch

Handshake:
- in_ready = feature_in_ready && risk_in_ready
- out_valid = signal_valid && risk_valid
- hold outputs stable while out_ready=0
- submodule out_ready driven by top out_ready

Return full synthesizable SystemVerilog.
```

---

# 🔒 Architectural Constraints Enforced Across All Prompts

- All arithmetic uses Q16.16
- All multiplications use fxp_mul_q16()
- All constants sourced from fxp_pkg
- No floating-point
- No division operators
- No manual scaling
- Ready/valid contract strictly followed

---

# 📌 Purpose of This Document

This file serves as:

- AI workflow transparency
- Reproducibility documentation
- Hackathon audit trail
- Engineering discipline evidence

All RTL was generated using AI under architect-defined numerical and interface constraints.
