read_liberty $::env(LIB)
read_db ./results/sky130hd/picorv32f/base/6_final.odb
read_sdc ./results/sky130hd/picorv32f/base/6_final.sdc
read_spef ./results/sky130hd/picorv32f/base/6_final.spef
report_checks -path_delay max -digits 3
report_wns
report_tns
