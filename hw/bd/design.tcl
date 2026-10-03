# SPDX-License-Identifier: MIT
# Authoritative block design. May be replaced with write_bd_tcl output.
create_bd_design system
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} $ps

# Initial Linux platform: no AXI peripherals or PL clock/reset consumers.
# The pinned board preset supplies DDR, UART0, SD0, GEM0 and USB0 wiring.
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {0} \
    CONFIG.PCW_EN_CLK0_PORT {0} \
    CONFIG.PCW_EN_CLK1_PORT {0} \
    CONFIG.PCW_EN_CLK2_PORT {0} \
    CONFIG.PCW_EN_CLK3_PORT {0} \
    CONFIG.PCW_EN_RST0_PORT {0} \
    CONFIG.PCW_EN_RST1_PORT {0} \
    CONFIG.PCW_EN_RST2_PORT {0} \
    CONFIG.PCW_EN_RST3_PORT {0}] $ps
validate_bd_design
save_bd_design
