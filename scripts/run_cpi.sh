#!/bin/bash
# Dung: bash scripts/run_cpi.sh   (chay tu bat ky dau; ket qua ghi vao results/cpi/cpi_results.txt)
cd "$(dirname "$0")/.."
python3 programs/gen.py || exit 1
iverilog -o sim2 tb/tb2.v rtl/picorv32.v || exit 1
for w in 0 1; do
  echo "######## wait=$w  (0: bo nho tra loi ngay, 1: co 1 chu ky cho)"
  for p in prog p_alu_imm p_alu_reg p_load p_store p_br_nt p_br_t p_jal p_shift; do
    printf "%-10s " $p; vvp sim2 +hex=programs/$p.hex +wait=$w | grep ket_qua
  done
done | tee results/cpi/cpi_results.txt
