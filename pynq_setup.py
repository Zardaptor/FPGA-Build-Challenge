import os

base_dir = r"c:\Users\suraj\Desktop\Projects\FPGA\FPGA-Build-Challenge-Suraj"

# Exp 2: Traffic Light XDC
os.makedirs(os.path.join(base_dir, "Experiment-2-Beginner", "Constraints"), exist_ok=True)
with open(os.path.join(base_dir, "Experiment-2-Beginner", "Constraints", "pynq_z2.xdc"), "w") as f:
    f.write("""## PYNQ-Z2 Constraints for Traffic Light
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; # 125MHz
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { rst }]; # BTN0
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { pedestrian_btn }]; # BTN1
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { emergency_override }]; # SW0

# Using RGB LED 4
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { red }];   # LED4_R
set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { yellow }];# LED4_B (Using Blue for Yellow)
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { green }]; # LED4_G
""")

# Exp 5: RISC-V XDC
os.makedirs(os.path.join(base_dir, "Experiment-5-Advanced", "Constraints"), exist_ok=True)
with open(os.path.join(base_dir, "Experiment-5-Advanced", "Constraints", "pynq_z2.xdc"), "w") as f:
    f.write("""## PYNQ-Z2 Constraints for RISC-V SoC
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; # 125MHz
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; # rst
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; 
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; 
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; 

set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
""")

print("PYNQ-Z2 Setup Complete!")
