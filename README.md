# PicoRV32 experiments

Measurements on the [PicoRV32](https://github.com/YosysHQ/picorv32) RISC-V core: cycles per instruction in
simulation, synthesis size for FPGA and ASIC under several configurations, place and route with
OpenROAD-flow-scripts on SKY130, timing across process corners and power from a gate-level simulation.

PicoRV32 is written by Claire Wolf and released under the ISC license; `rtl/picorv32.v` is an unmodified
copy. The testbenches, test programs, scripts and results in this repository are mine.

## Layout

| Folder | Contents |
|---|---|
| `rtl/` | `picorv32.v` (upstream) |
| `tb/` | `tb.v` (runs `programs/prog.hex`), `tb2.v` (CPI measurement, optional memory wait state), `tb_gl.v` (gate-level netlist) |
| `programs/` | `gen.py` generates one test program per instruction class; `prog.hex` is the main test program |
| `scripts/` | `run_cpi.sh`, `synth_all.sh`, `gl_power.sh`, `corner.tcl`, `corner_f.tcl` |
| `results/` | `cpi/`, `synth/`, `timing/`, `power/`, `orfs/` |

## Cycles per instruction

Each program repeats one instruction class about 100 times (`programs/gen.py`). Numbers are total cycles /
instructions from `tb2.v`, with memory answering in the same cycle (wait 0) or one cycle later (wait 1).

| Program | Cycles / instructions (wait 0) | CPI wait 0 | CPI wait 1 |
|---|---|---|---|
| ALU immediate | 307 / 101 | 3.04 | 4.06 |
| ALU register | 310 / 102 | 3.04 | 4.06 |
| Load | 507 / 101 | 5.02 | 7.03 |
| Store | 507 / 101 | 5.02 | 7.03 |
| Branch not taken | 307 / 101 | 3.04 | 4.06 |
| Branch taken | 507 / 101 | 5.02 | 7.03 |
| JAL | 307 / 101 | 3.04 | 4.06 |
| Shift | 610 / 102 | 5.98 | 6.02 |
| Mixed program (`prog.hex`) | 121 / 33 | 3.67 | 5.00 |

PicoRV32 is a multi-cycle core with no pipeline, so CPI is 3 to 6 depending on the instruction; a wait state
adds one cycle per memory access (one for the fetch, one more for a load or store). The default shifter
shifts by at most 4 bits per cycle (`TWO_STAGE_SHIFT`), so shift time depends on the shift amount and barely
changes with a wait state. `tb.v` has its own memory model and runs `prog.hex` in 164 cycles (CPI 4.97).

## Synthesis

Configurations (Verilog parameters set with `chparam`):

- default: upstream defaults.
- small: no cycle/instret counters, registers x16 to x31 removed (RV32E), no misaligned-access and illegal
  instruction traps.
- large: hardware multiply and divide, barrel shifter, compressed instructions, interrupts.

FPGA, Yosys 0.69 `synth_xilinx -family xc7`:

| Config | LUT | FF | CARRY4 |
|---|---|---|---|
| small | 913 | 433 | 64 |
| default | 1,041 | 573 | 96 |
| large | 2,501 | 1,237 | 189 |

ASIC, Yosys + ABC mapped to `sky130_fd_sc_hd`:

| Config | Cells (Yosys 0.52) | Area µm² (Yosys 0.52) | Area µm² (Yosys 0.69) |
|---|---|---|---|
| small | 3,991 | 47,997 | 47,404 |
| registers x16 to x31 removed only | 4,661 | 53,728 | – |
| default | 5,709 | 77,270 | 78,137 |

About 56 to 57 % of the area is flip-flops, most of it the register file; removing x16 to x31 alone saves
about 30 % of the area.

## Place and route (OpenROAD-flow-scripts, SKY130 HD)

Default configuration, 10 ns clock: 6,306 cells and 83,521 µm² after ORFS synthesis, worst setup slack
+3.93 ns, TNS 0 (typical corner). A second run (`picorv32f`) targets a 5.5 ns clock. Layout and worst path
screenshots are in `results/orfs/`.

Setup timing of the routed design across corners (`scripts/corner*.tcl`, with SPEF parasitics):

| Corner | Arrival, 10 ns run | Slack | Arrival, 5.5 ns run | Slack |
|---|---|---|---|---|
| ff, -40 °C, 1.95 V | 2.86 ns | +5.14 ns | 3.10 ns | +1.90 ns |
| tt, 25 °C, 1.80 V | 4.07 ns | +3.93 ns | 5.90 ns | +0.27 ns |
| ss, 100 °C, 1.60 V | 12.76 ns | −1.51 ns | 11.70 ns | −5.14 ns |

Both runs meet timing at the typical corner and fail at the slow corner, because ORFS only signs off the
typical corner. The 10 ns run would need about 13 ns to pass at ss.

## Power

Gate-level simulation of the routed netlist running `prog.hex` (`scripts/gl_power.sh`), switching activity
from the VCD annotated onto 26,187 pins (10 unannotated), then OpenROAD `report_power` at the typical corner:

| Run | Clock | Internal | Switching | Leakage | Total |
|---|---|---|---|---|---|
| picorv32 | 10 ns | 11.8 mW | 4.0 mW | 36 nW | 15.8 mW |
| picorv32f | 5.5 ns | 20.6 mW | 6.4 mW | 36 nW | 27.0 mW |

Flip-flops take 47 % and the clock tree 44 % of the 10 ns total. Power scales roughly with clock frequency
(1.82× the frequency, 1.71× the power).

## Running

```
bash scripts/run_cpi.sh                 # Icarus Verilog + Python 3; writes results/cpi/cpi_results.txt
bash scripts/synth_all.sh yosys 0.69    # needs sky130.lib (sky130_fd_sc_hd) in the repository root, not committed
bash scripts/gl_power.sh picorv32 5     # needs OpenROAD-flow-scripts at ~/OpenROAD-flow-scripts after a finished run
```

`corner.tcl` and `corner_f.tcl` are run from the `flow/` folder of OpenROAD-flow-scripts as
`LIB=<file .lib> openroad -exit <script>`.

## Limits

- The CPI programs are short loops of one instruction class, not a benchmark.
- `results/synth/root_run` is an earlier run whose script is not kept; its numbers match `yosys_0.52`.
- Only the typical corner was signed off in ORFS; the corner tables are analysis of the same routed design.
