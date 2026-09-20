module instruction_memory(
    input wire [31:0] addr,
    output reg [31:0] instr
);
    wire [31:0] word_addr = addr >> 2;
    always @(*) begin
        case (word_addr)
            32'd0: instr = 32'h00500513; // addi x10, x0, 5
            32'd1: instr = 32'h00450513; // addi x10, x10, 4 (x10 = 9)
            32'd2: instr = 32'h0000006f; // jal x0, 0 (halt)
            default: instr = 32'h00000013; // nop
        endcase
    end
endmodule
