`timescale 1ns / 1ps

module tb_traffic_light;

    reg clk;
    reg rst;
    reg pedestrian_btn;
    reg emergency_override;
    wire red;
    wire yellow;
    wire green;

    // Instantiate with overridden parameter for fast simulation
    traffic_light #(
        .CLK_FREQ(5),      // 1Hz tick every 5 clock cycles
        .DEBOUNCE_MAX(2)   // Fast debounce for sim
    ) uut (
        .clk(clk),
        .rst(rst),
        .pedestrian_btn(pedestrian_btn),
        .emergency_override(emergency_override),
        .red(red),
        .yellow(yellow),
        .green(green)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test sequence
    initial begin
        $display("Starting traffic light simulation...");
        rst = 1;
        pedestrian_btn = 0;
        emergency_override = 0;
        
        #20;
        rst = 0;
        
        $monitor("Time=%0t | rst=%b ped=%b emerg=%b | state: R=%b Y=%b G=%b", 
                 $time, rst, pedestrian_btn, emergency_override, red, yellow, green);
        
        // 1. Simulate normal operation (wait for a full cycle)
        // Red(5 ticks), Yellow1(1 tick), Green(5 ticks), Yellow2(1 tick)
        // 1 tick = 5 clock cycles = 50ns
        // Full cycle = 12 ticks = 600ns
        #800; 

        // 2. Assert emergency override
        // Wait until it reaches Red again to test emergency override behavior
        wait(red == 1);
        #20;
        $display("Time=%0t | Asserting emergency override!", $time);
        emergency_override = 1;
        
        // Wait and observe transition to Green and hold
        #300; 
        
        $display("Time=%0t | Deasserting emergency override!", $time);
        emergency_override = 0;
        
        // Wait for it to return to normal cycle and reach Green
        wait(green == 1);
        #50; // Let it be in Green for a bit
        
        // 3. Test pedestrian button interrupt
        $display("Time=%0t | Pressing pedestrian button!", $time);
        pedestrian_btn = 1;
        #50; // hold long enough to debounce
        pedestrian_btn = 0;
        
        // Observe safe transition to Red and hold for 5s (5 ticks = 250ns)
        #600;

        $display("Time=%0t | Simulation complete.", $time);
        $finish;
    end

endmodule
