# Using `fxp_pkg.sv`

## Overview

`fxp_pkg.sv` centralizes all fixed-point configuration, constants, and helper functions for QuantSilicon.

All modules must import this package to ensure:

* Consistent Q16.16 scaling
* Centralized architectural constants
* No hardcoded numeric values
* No duplicated scaling logic

---

## What It Contains

### 1️⃣ Fixed-Point Configuration

* Q16.16 format definition
* Fractional bit width (`FXP_FRAC = 16`)

---

### 2️⃣ Frozen Architectural Constants

* `ALPHA_SHIFT`
* `W1`
* `W2`
* `LIMIT`

These must never be hardcoded inside modules.

---

### 3️⃣ Utility Functions

* `fxp_mul_q16(a, b)`

  * Performs 64-bit multiply
  * Automatically rescales back to Q16.16

* `fxp_abs(x)`

  * Safe signed absolute value

---

## How To Use in a Module

At the top of every RTL module:

```systemverilog
import fxp_pkg::*;
```

### Example: Fixed-Point Multiplication

```systemverilog
signal_term = fxp_mul_q16(trend, W1);
```

Do NOT write:

```systemverilog
signal_term = (trend * 32'sd49152) >>> 16;  // ❌ Not allowed
```

---

## Rules

All CogniChip-generated RTL must:

* Import `fxp_pkg::*`
* Use `fxp_mul_q16()` for every Q16.16 multiplication
* Use `fxp_abs()` for absolute value
* Use constants only from `fxp_pkg`
* Never manually write `>>> 16`
* Never hardcode scaled integers
* Never use `real` types
* Never use `/` division operators

---

## Why This Matters

Using `fxp_pkg`:

* Prevents scaling inconsistencies
* Prevents silent overflow bugs
* Enables easy weight updates
* Keeps AI-generated RTL disciplined
* Maintains architectural integrity

