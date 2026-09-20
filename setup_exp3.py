import os

base_dir = r"c:\Users\suraj\Desktop\Projects\FPGA\FPGA-Build-Challenge-Suraj\Experiment-3-Intermediate"
rtl_dir = os.path.join(base_dir, "RTL")
xdc_dir = os.path.join(base_dir, "Constraints")

# 1. Write uart_pynq_test_top.v
with open(os.path.join(rtl_dir, "uart_pynq_test_top.v"), "w") as f:
    f.write('''module uart_pynq_test_top #(
    parameter CLKS_PER_BIT = 13020 // 125MHz / 9600 baud
)(
    input  wire clk,
    input  wire [3:0] btn,
    output wire [3:0] led,
    output wire tx_pin,
    output wire led4_r // Parity Error LED
);
    wire rst = btn[0];

    // 1 Hz Auto-Send Timer
    reg [26:0] clk_cnt;
    reg send_tick;
    always @(posedge clk) begin
        if (rst) begin
            clk_cnt <= 0;
            send_tick <= 0;
        end else if (clk_cnt == 125_000_000) begin
            clk_cnt <= 0;
            send_tick <= 1;
        end else begin
            clk_cnt <= clk_cnt + 1;
            send_tick <= 0;
        end
    end

    // Data to send (Counting up)
    reg [7:0] tx_data_reg;
    always @(posedge clk) begin
        if (rst) tx_data_reg <= 8'h01;
        else if (send_tick) tx_data_reg <= tx_data_reg + 1;
    end

    // Instantiate TX
    wire tx_serial;
    wire tx_busy;
    uart_tx #( .CLKS_PER_BIT(CLKS_PER_BIT) ) u_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(send_tick),
        .tx_data(tx_data_reg),
        .tx(tx_serial),
        .tx_busy(tx_busy)
    );

    // Output to physical Pmod Pin for logic analyzer proof
    assign tx_pin = tx_serial;

    // INTERNAL LOOPBACK
    wire rx_serial = tx_serial;

    // Instantiate RX
    wire [7:0] rx_data;
    wire rx_valid;
    wire parity_err;
    uart_rx #( .CLKS_PER_BIT(CLKS_PER_BIT) ) u_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx_serial),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .parity_err(parity_err)
    );

    // Display received data on LEDs
    reg [3:0] led_reg;
    always @(posedge clk) begin
        if (rst) led_reg <= 0;
        else if (rx_valid) led_reg <= rx_data[3:0];
    end
    
    assign led = led_reg;
    assign led4_r = parity_err;

endmodule
''')

# 2. Update pynq_z2.xdc
with open(os.path.join(xdc_dir, "pynq_z2.xdc"), "w") as f:
    f.write('''## PYNQ-Z2 Constraints for UART Auto-Test
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; 
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; 
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; 
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; 
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; 

set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { tx_pin }];
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { led4_r }];
''')

print("Exp 3 hardware wrapper and XDC generated successfully!")
