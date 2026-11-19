#!/bin/bash
# dung: bash scripts/gl_power.sh <ten_thiet_ke: picorv32 | picorv32f> <nua_chu_ky_ns: 5 | 2.75>
# Can OpenROAD-flow-scripts da chay xong thiet ke o $HOME/OpenROAD-flow-scripts va PDK sky130 cai bang volare.
# Ket qua cong suat ghi vao results/power/pw_<ten>.txt.
N=$1; H=$2
F=$HOME/OpenROAD-flow-scripts/flow
D=$(dirname $(find ~/pdk/volare/sky130 -path '*sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib' | head -1))
V=$D/../verilog
cd "$(dirname "$0")/.."
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY='#0.01' -P tb_gl.HALF=$H -o gl_$N tb/tb_gl.v \
  $F/results/sky130hd/$N/base/6_final.v $V/primitives.v $V/sky130_fd_sc_hd.v || exit 1
vvp gl_$N | tail -3
mv wave_gl.vcd wave_gl_$N.vcd
cat > pw_$N.tcl <<EOT
read_liberty $F/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_db $F/results/sky130hd/$N/base/6_final.odb
read_sdc $F/results/sky130hd/$N/base/6_final.sdc
read_spef $F/results/sky130hd/$N/base/6_final.spef
read_vcd -scope tb_gl/dut wave_gl_$N.vcd
report_activity_annotation
report_power
EOT
openroad -no_splash -exit pw_$N.tcl > results/power/pw_$N.txt 2>&1
grep -E -i "annotat|Total|Sequential|Combinational|Clock|rror" results/power/pw_$N.txt | head -25
