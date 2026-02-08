<h1 align="center">game_opt — Android Ultimate Performance Script</h1>

<div align="center">
  <img src="https://img.shields.io/badge/Script-game-red.svg?style=flat-square" />
  <img src="https://img.shields.io/badge/Target-Android%2013%2B-purple.svg?style=flat-square" />
  <img src="https://img.shields.io/badge/Kernel-Linux%205.4+-orange.svg?style=flat-square" />
</div>
<div align="center">
  <a href="https://github.com/jpzex/batt_opt">
  <img src="https://img.shields.io/badge/SUGGESTED_COMBO-base+batt-green.svg?style=flat-square" /></a>
  <a href="https://github.com/jpzex/game_opt">
  <img src="https://img.shields.io/badge/SUGGESTED_COMBO-base+game-red.svg?style=flat-square" /></a>
</div>

---

## Overview

**game_opt** is an aggressively performance-biased script meant to be used alongside `base_opt`.  
Its goal is to **prioritize the foreground application or game at all costs**, regardless of battery drain or thermals.  
This profile is intentionally hostile to power efficiency and directly conflicts with `batt_opt`.  

---

## Design Intent

- Minimize input-to-frame latency
- Maximize foreground CPU and GPU residency
- Eliminate scheduler hesitation and buffering
- Favor determinism over efficiency

`game_opt` intentionally undoes many assumptions made by `batt_opt`.

---

## How It Works

- Disables energy-aware scheduling and fairness heuristics
- Forces rapid task migration toward big cores
- Shortens scheduler wakeup and time slice paths
- Disables adaptive buffering and slow-start logic
- Prefers small, fixed memory buffers for predictability
- Aggressively reclaims cache and background memory
- Keeps CPU and GPU in high-performance states longer

The kernel is encouraged to:

> **Respond immediately, boost aggressively, and ignore cost.**

---

## Impact

- Lowest achievable system latency
- Faster input response and frame delivery
- Higher sustained clocks and thermal output
- Increased battery drain and memory pressure

Ideal for competitive gaming, benchmarks, and latency-sensitive workloads.
