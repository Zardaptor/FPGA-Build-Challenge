`timescale 1ns / 1ps

module tb_alu_advanced;

    // Parameters
    parameter WIDTH = 8;

    // Inputs
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    reg [2:0] opcode;

    // Outputs
    wire [WIDTH-1:0] result;
    wire N, Z, C, V;

    // Instantiate the Unit Under Test (UUT)
    alu_advanced #(
        .WIDTH(WIDTH)
    ) uut (
        .a(a), 
        .b(b), 
        .opcode(opcode), 
        .result(result), 
        .N(N), 
        .Z(Z), 
        .C(C), 
        .V(V)
    );

    initial begin
        // Initialize Inputs
        a = 0;
        b = 0;
        opcode = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        $display("Starting ALU Testbench...");

        // Test ADD without overflow
        a = 8'h10; b = 8'h20; opcode = 3'b000;
        #10;
        $display("ADD: %h + %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        // Test ADD with overflow
        a = 8'h7F; b = 8'h01; opcode = 3'b000;
        #10;
        $display("ADD OVF: %h + %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        // Test SUB
        a = 8'h50; b = 8'h20; opcode = 3'b001;
        #10;
        $display("SUB: %h - %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        // Test SUB with negative result
        a = 8'h20; b = 8'h50; opcode = 3'b001;
        #10;
        $display("SUB NEG: %h - %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        // Test SUB with overflow
        a = 8'h80; b = 8'h01; opcode = 3'b001;
        #10;
        $display("SUB OVF: %h - %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        // Test AND
        a = 8'hF0; b = 8'hAA; opcode = 3'b010;
        #10;
        $display("AND: %h & %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test OR
        a = 8'hF0; b = 8'h0F; opcode = 3'b011;
        #10;
        $display("OR: %h | %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test XOR
        a = 8'hAA; b = 8'h55; opcode = 3'b100;
        #10;
        $display("XOR: %h ^ %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test SHIFT LEFT
        a = 8'h01; b = 8'h04; opcode = 3'b101;
        #10;
        $display("SHL: %h << %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test SHIFT RIGHT
        a = 8'h80; b = 8'h03; opcode = 3'b110;
        #10;
        $display("SHR: %h >> %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test MULTIPLY
        a = 8'h05; b = 8'h06; opcode = 3'b111;
        #10;
        $display("MULT: %h * %h = %h (N=%b, Z=%b)", a, b, result, N, Z);

        // Test ZERO flag
        a = 8'h00; b = 8'h00; opcode = 3'b000;
        #10;
        $display("ZERO ADD: %h + %h = %h (N=%b, Z=%b, C=%b, V=%b)", a, b, result, N, Z, C, V);

        $display("Testbench completed.");
        $finish;
    end

endmodule
