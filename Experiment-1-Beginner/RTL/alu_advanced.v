`timescale 1ns / 1ps

module alu_advanced #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0] opcode,
    output reg  [WIDTH-1:0] result,
    output wire N,
    output wire Z,
    output reg  C,
    output reg  V
);

    // Opcodes definition
    localparam OP_ADD  = 3'b000;
    localparam OP_SUB  = 3'b001;
    localparam OP_AND  = 3'b010;
    localparam OP_OR   = 3'b011;
    localparam OP_XOR  = 3'b100;
    localparam OP_SHL  = 3'b101;
    localparam OP_SHR  = 3'b110;
    localparam OP_MULT = 3'b111;

    reg [WIDTH:0] temp_result;

    always @(*) begin
        // Default values
        result = {WIDTH{1'b0}};
        C = 1'b0;
        V = 1'b0;
        temp_result = {(WIDTH+1){1'b0}};

        case (opcode)
            OP_ADD: begin
                temp_result = {1'b0, a} + {1'b0, b};
                result = temp_result[WIDTH-1:0];
                C = temp_result[WIDTH];
                V = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            OP_SUB: begin
                temp_result = {1'b0, a} - {1'b0, b};
                result = temp_result[WIDTH-1:0];
                C = temp_result[WIDTH]; // borrow flag
                V = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            OP_AND: begin
                result = a & b;
            end
            OP_OR: begin
                result = a | b;
            end
            OP_XOR: begin
                result = a ^ b;
            end
            OP_SHL: begin
                result = a << b;
            end
            OP_SHR: begin
                result = a >> b;
            end
            OP_MULT: begin
                result = a * b;
            end
            default: begin
                result = {WIDTH{1'b0}};
            end
        endcase
    end

    // Negative and Zero flags
    assign N = result[WIDTH-1];
    assign Z = (result == {WIDTH{1'b0}});

endmodule
