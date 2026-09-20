`timescale 1ns/1ps

module tb_uart;

    reg clk;
    reg rst;
    reg rx;
    wire tx;
    wire parity_err_led;
    
    // Fast simulation timing, 160 clocks per bit allows 10 clocks per oversample tick
    parameter CLKS_PER_BIT = 160;
    
    uart_echo_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .parity_err_led(parity_err_led)
    );
    
    // 100MHz clock (10ns period)
    always #5 clk = ~clk; 
    
    task send_byte;
        input [7:0] data;
        input force_parity_err;
        integer i;
        reg parity;
        begin
            parity = ^data; // Calculate Even Parity
            if (force_parity_err) parity = ~parity; // Inject error
            
            // Start bit
            rx = 0;
            #(10 * CLKS_PER_BIT);
            
            // Data bits
            for (i=0; i<8; i=i+1) begin
                rx = data[i];
                #(10 * CLKS_PER_BIT);
            end
            
            // Parity bit
            rx = parity;
            #(10 * CLKS_PER_BIT);
            
            // Stop bit
            rx = 1;
            #(10 * CLKS_PER_BIT);
        end
    endtask
    
    initial begin
        $dumpfile("tb_uart.vcd");
        $dumpvars(0, tb_uart);
        
        clk = 0;
        rst = 1;
        rx = 1;
        
        #100;
        rst = 0;
        #100;
        
        // 1. Send normal byte (e.g., 8'hA5 -> 10100101, even parity = 0)
        $display("Sending 8'hA5 with correct parity...");
        send_byte(8'hA5, 0);
        
        // Wait for echo to complete (15 bit periods is enough buffer)
        #(10 * CLKS_PER_BIT * 15);
        
        // 2. Send byte with parity error (e.g., 8'h3C, flipped parity)
        $display("Sending 8'h3C with forced parity error...");
        send_byte(8'h3C, 1);
        
        // Wait for echo to complete
        #(10 * CLKS_PER_BIT * 15);
        
        if (parity_err_led)
            $display("SUCCESS: Parity error LED successfully triggered!");
        else
            $display("ERROR: Parity error LED did not trigger!");
            
        #500;
        $finish;
    end
    
endmodule
