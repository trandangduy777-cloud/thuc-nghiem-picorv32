#!/bin/bash
# Dung: ./synth_all.sh <lenh-yosys> <nhan>     vd: ./synth_all.sh yosys v052
# Chay 3 cau hinh FPGA (xc7) + 2 cau hinh ASIC (SKY130) va in bang tom tat.
Y=${1:-yosys}; T=${2:-run}
GON="-set ENABLE_COUNTERS 0 -set ENABLE_COUNTERS64 0 -set ENABLE_REGS_16_31 0 -set CATCH_MISALIGN 0 -set CATCH_ILLINSN 0"
LON="-set ENABLE_MUL 1 -set ENABLE_DIV 1 -set BARREL_SHIFTER 1 -set COMPRESSED_ISA 1 -set ENABLE_IRQ 1"
mkdir -p out_$T
$Y -V | tee out_$T/version.txt
fpga() { # ten  tham-so
  P=""; [ -n "$2" ] && P="chparam $2 picorv32;"
  $Y -q -p "read_verilog picorv32.v; $P synth_xilinx -flatten -top picorv32 -family xc7; tee -o out_$T/xc7_$1.txt stat" > out_$T/log_xc7_$1.txt 2>&1
}
asic() {
  P=""; [ -n "$2" ] && P="chparam $2 picorv32;"
  $Y -q -p "read_verilog picorv32.v; $P synth -flatten -top picorv32; dfflibmap -liberty sky130.lib; abc -liberty sky130.lib; opt_clean -purge; tee -o out_$T/asic_$1.txt stat -liberty sky130.lib" > out_$T/log_asic_$1.txt 2>&1
}
fpga mac_dinh ""; fpga gon "$GON"; fpga lon "$LON"
asic mac_dinh ""; asic gon "$GON"
echo "== FPGA xc7 ($T)"
for f in mac_dinh gon lon; do
  awk -v n=$f '/LUT[1-6]( |$)/{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){l+=$i;break}} /FD[CPRS]E( |$)/{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){ff+=$i;break}} /CARRY4( |$)/{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){c+=$i;break}} END{printf "%-8s LUT=%d FF=%d CARRY4=%d\n",n,l,ff,c}' out_$T/xc7_$f.txt
done
echo "== ASIC SKY130 ($T)"
for f in mac_dinh gon; do
  echo "-- $f"; grep -E "Number of cells:|dfxtp_1|edfxtp_1|Chip area|sequential" out_$T/asic_$f.txt
done
