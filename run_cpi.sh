#!/bin/bash
# Dung: ./run_cpi.sh      (can co picorv32.v, prog.hex, tb2.v, gen.py trong cung thu muc)
python3 gen.py || exit 1
iverilog -o sim2 tb2.v picorv32.v || exit 1
for w in 0 1; do
  echo "######## wait=$w  (0: bo nho tra loi ngay, 1: co 1 chu ky cho)"
  for p in prog p_alu_imm p_alu_reg p_load p_store p_br_nt p_br_t p_jal p_shift; do
    printf "%-10s " $p; vvp sim2 +hex=$p.hex +wait=$w | grep ket_qua
  done
done | tee cpi_results.txt
