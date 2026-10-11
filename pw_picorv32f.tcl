read_liberty /home/trandangduy/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_db /home/trandangduy/OpenROAD-flow-scripts/flow/results/sky130hd/picorv32f/base/6_final.odb
read_sdc /home/trandangduy/OpenROAD-flow-scripts/flow/results/sky130hd/picorv32f/base/6_final.sdc
read_spef /home/trandangduy/OpenROAD-flow-scripts/flow/results/sky130hd/picorv32f/base/6_final.spef
read_vcd -scope tb_gl/dut wave_gl_picorv32f.vcd
report_activity_annotation
report_power
