## Zybo (Original) Constraints File — RISC-V RV32I Processor
## Project: V-SPACE FPGA Build Challenge 2026
## Board: Digilent Zybo Zynq-7000 (XC7Z010-1CLG400C)
## Author: Team Suraj
##
## Reference: Zybo Reference Manual & Master XDC
## https://digilent.com/reference/programmable-logic/zybo/reference-manual

## ============================================================================
## Clock — 125 MHz system clock
## ============================================================================
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 8.000 -name sys_clk_125 [get_ports clk]

## ============================================================================
## Push Buttons (active-high)
##   BTN0 = Reset
##   BTN1-3 = unused (active high when pressed)
## ============================================================================
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {btn[2]}]
set_property -dict { PACKAGE_PIN Y16 IOSTANDARD LVCMOS33 } [get_ports {btn[3]}]

## ============================================================================
## LEDs (active-high)
##   LD0-LD3 = Lower 4 bits of register a0 (x10)
## ============================================================================
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## ============================================================================
## Slide Switches (active-high)
##   Not used in RISC-V processor, but available for future expansion
## ============================================================================
# set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
# set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
# set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
# set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
