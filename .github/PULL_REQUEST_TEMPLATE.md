## Summary
Brief summary of the RTL, constraint, simulation, or tooling change.

## Checklist
- [ ] Tested with Vivado `xsim` (`sim/run_sim.ps1`) or `iverilog`
- [ ] Verified Vivado timing (`WNS >= 0 ns`, `0 Latches`) if RTL changed
- [ ] All `.mem` assets and paths remain portable (no hardcoded local paths)
