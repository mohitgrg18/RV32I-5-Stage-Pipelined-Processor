`timescale 1ns / 1ps

module alu(
    input [31:0]A,
    input[31:0]B,
    input [3:0]alu_control,
    output reg[31:0]alu_result,
    output zero
);

localparam ALU_ADD = 4'b0000,
           ALU_SUB = 4'b0001,
           ALU_AND = 4'b0010,
           ALU_OR =  4'b0011,
           ALU_XOR = 4'b0100,
           ALU_SLL = 4'b0101,
           ALU_SRL = 4'b0110,
           ALU_SRA = 4'b0111,
           ALU_SLT = 4'b1000,
           ALU_SLTU = 4'b1001;

always@(*)begin
case(alu_control)
       ALU_ADD : alu_result = A + B;
       ALU_SUB : alu_result = A - B;
       ALU_AND : alu_result = A & B;
       ALU_OR  : alu_result = A | B;
       ALU_XOR : alu_result = A ^ B;
       ALU_SLL : alu_result = A << B[4:0];
       ALU_SRL : alu_result = A >> B[4:0];
       ALU_SRA : alu_result = $signed(A) >>> B[4:0];
       ALU_SLT : alu_result = $signed(A) < $signed(B) ? 32'b1 : 32'b0;
       ALU_SLTU : alu_result = A < B ? 32'b1 : 32'b0;
       default : alu_result = 32'b0;
    endcase
end


assign zero = (alu_result == 0);

endmodule 




 