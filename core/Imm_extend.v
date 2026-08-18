`timescale 1ns / 1ps

module imm_extend(
    input [31:0]instr,
    input [2:0]imm_src,
    output [31:0]imm_ext //32 bit sign extended immediate
);

reg [31:0]imm_ext_reg;

localparam Imm_I = 3'b000,
          Imm_S = 3'b001,
          Imm_B = 3'b010,
          Imm_J = 3'b011,
          Imm_U = 3'b100;


always@(*)begin
case(imm_src)
       // I type for addi , lw
    Imm_I   :  imm_ext_reg = {{20{instr[31]}},instr[31:20]};
       // S type for sw
    Imm_S : imm_ext_reg = {{20{instr[31]}},instr[31:25],instr[11:7]};   
       // B type for beq,bne
    Imm_B : imm_ext_reg = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
      // J type for jal
    Imm_J : imm_ext_reg = {{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
      // U type for lui , auipc
    Imm_U : imm_ext_reg = {instr[31:12] , 12'b0};  

    default : imm_ext_reg = 32'b0;

    endcase
end

assign imm_ext = imm_ext_reg;

endmodule 

