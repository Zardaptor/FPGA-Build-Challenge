module instruction_memory(
    input wire [31:0] addr,
    output reg [31:0] instr
);
    wire [31:0] word_addr = addr >> 2;
    always @(*) begin
        case (word_addr)
            32'd0: instr = 32'h00000293; // addi x5, x0, 0
            32'd1: instr = 32'h00100093; // addi x1, x0, 1
            32'd2: instr = 32'h00000113; // addi x2, x0, 0
            32'd3: instr = 32'h00a00193; // addi x3, x0, 10
            32'd4: instr = 32'h00000213; // addi x4, x0, 0
            32'd5: instr = 32'h00208333; // add x6, x1, x2
            32'd6: instr = 32'h0062a023; // sw x6, 0(x5)
            32'd7: instr = 32'h00008533; // add x10, x0, x1
            32'd8: instr = 32'h002080b3; // add x1, x0, x2
            32'd9: instr = 32'h00608133; // add x2, x0, x6
            32'd10: instr = 32'h00428293; // addi x5, x5, 4
            32'd11: instr = 32'h00120213; // addi x4, x4, 1
            32'd12: instr = 32'hfe3214e3; // bne x4, x3, -24
            32'd13: instr = 32'h0000006f; // jal x0, 0
            default: instr = 32'h00000013; // nop
        endcase
    end
endmodule
