## PYNQ-Z2 Constraints for Traffic Light
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; # 125MHz
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { rst }]; # BTN0
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { pedestrian_btn }]; # BTN1
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { emergency_override }]; # SW0

# Using RGB LED 4
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { red }];   # LED4_R
set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { yellow }];# LED4_B (Using Blue for Yellow)
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { green }]; # LED4_G
