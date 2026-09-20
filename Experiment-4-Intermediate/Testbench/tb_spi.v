`timescale 1ns/1ps

module tb_spi;

    reg clk;
    reg rst;
    reg [7:0] switch_in;
    reg send_btn;
    reg cpol_sw;
    reg cpha_sw;
    reg slave_select_sw;
    wire [7:0] led_out;

    spi_loopback_top uut (
        .clk(clk),
        .rst(rst),
        .switch_in(switch_in),
        .send_btn(send_btn),
        .cpol_sw(cpol_sw),
        .cpha_sw(cpha_sw),
        .slave_select_sw(slave_select_sw),
        .led_out(led_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    initial begin
        rst = 1;
        switch_in = 0;
        send_btn = 0;
        cpol_sw = 0;
        cpha_sw = 0;
        slave_select_sw = 0;

        #100;
        rst = 0;
        #100;

        // Test 1: Mode 0 (CPOL=0, CPHA=0), Slave 0
        $display("Testing Mode 0, Slave 0");
        cpol_sw = 0;
        cpha_sw = 0;
        slave_select_sw = 0;
        switch_in = 8'hA5;
        #20;
        send_btn = 1;
        #20;
        send_btn = 0;
        #3000;
        if (led_out == 8'hA5) $display("Mode 0 Slave 0 PASS");
        else $display("Mode 0 Slave 0 FAIL, got %h", led_out);

        // Test 2: Mode 0, Slave 1
        $display("Testing Mode 0, Slave 1");
        slave_select_sw = 1;
        switch_in = 8'h5A;
        #20;
        send_btn = 1;
        #20;
        send_btn = 0;
        #3000;
        if (led_out == 8'h5A) $display("Mode 0 Slave 1 PASS");
        else $display("Mode 0 Slave 1 FAIL, got %h", led_out);

        // Test 3: Mode 3 (CPOL=1, CPHA=1), Slave 0
        $display("Testing Mode 3, Slave 0");
        cpol_sw = 1;
        cpha_sw = 1;
        slave_select_sw = 0;
        switch_in = 8'h3C;
        #20;
        send_btn = 1;
        #20;
        send_btn = 0;
        #3000;
        if (led_out == 8'h3C) $display("Mode 3 Slave 0 PASS");
        else $display("Mode 3 Slave 0 FAIL, got %h", led_out);

        // Test 4: Mode 3, Slave 1
        $display("Testing Mode 3, Slave 1");
        cpol_sw = 1;
        cpha_sw = 1;
        slave_select_sw = 1;
        switch_in = 8'hC3;
        #20;
        send_btn = 1;
        #20;
        send_btn = 0;
        #3000;
        if (led_out == 8'hC3) $display("Mode 3 Slave 1 PASS");
        else $display("Mode 3 Slave 1 FAIL, got %h", led_out);

        $display("All tests finished.");
        $finish;
    end

endmodule
