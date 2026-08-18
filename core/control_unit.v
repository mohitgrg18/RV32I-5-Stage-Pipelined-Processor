`timescale 1ns / 1ps

module control_unit(
    input [6:0]opcode,
    input [6:0]funct7,
    input [2:0]funct3,

    output reg reg_wr,
    output reg mem_rd,
    output reg mem_wr,
    output reg branch,
    output reg jal,
    output reg jalr,
    output reg memtoreg,
    output reg alu_src,
    output reg [2:0]imm_src,
    output reg [3:0]alu_control,
    output reg [2:0]load_type,
    output reg [1:0]store_type,
    output reg [2:0]branch_type,
    output reg [1:0]result_src,
    output reg lui,
    output reg auipc

);


wire[9:0]funct;
assign funct = {funct7,funct3};

localparam Imm_I = 3'b000,
           Imm_S = 3'b001,
           Imm_B = 3'b010,
           Imm_J = 3'b011,
           Imm_U = 3'b100;

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

localparam LOAD_LW = 3'b000,
           LOAD_LB = 3'b001,
           LOAD_LH = 3'b010,
           LOAD_LBU = 3'b011,
           LOAD_LHU = 3'b100;

localparam STORE_SW = 2'b00,
           STORE_SH = 2'b01,
           STORE_SB = 2'b10;

localparam ALU_SRC_REG = 1'b0,
           ALU_SRC_IMM = 1'b1;

localparam RESULT_SRC_MEM = 2'b00,
           RESULT_SRC_ALU = 2'b01,
           RESULT_SRC_PC = 2'b10;

localparam BRANCH_BEQ = 3'b000,
           BRANCH_BNE = 3'b001,
           BRANCH_BLT = 3'b010,
           BRANCH_BGE = 3'b100,
           BRANCH_BLTU = 3'b101,
           BRANCH_BGEU = 3'b110;


always@(*)begin
//default 
reg_wr = 0;
mem_rd = 0;
mem_wr = 0;
jal = 0;
jalr = 0;
branch = 0;
memtoreg = 0;
alu_src = ALU_SRC_REG;
imm_src = Imm_I;
alu_control = ALU_ADD;
load_type = LOAD_LW;
store_type = STORE_SW;
branch_type = BRANCH_BEQ;
result_src = RESULT_SRC_ALU;
lui = 0;
auipc = 0;


case(opcode)
   7'b0110011 : begin  // R type
        reg_wr = 1;
        alu_src = ALU_SRC_REG;
        result_src = RESULT_SRC_ALU;
        case(funct)
        10'b0000000000 : alu_control = ALU_ADD;
        10'b0100000000 : alu_control = ALU_SUB;
        10'b0000000111 : alu_control = ALU_AND;
        10'b0000000110 : alu_control = ALU_OR;
        10'b0000000100 : alu_control = ALU_XOR;
        10'b0000000001 : alu_control = ALU_SLL;
        10'b0000000101 : alu_control = ALU_SRL;
        10'b0100000101 : alu_control = ALU_SRA;
        10'b0000000010 : alu_control = ALU_SLT;
        10'b0000000011 : alu_control = ALU_SLTU;
        default : alu_control = ALU_ADD;
        endcase
        end


     7'b0010011 : begin // I-type
         reg_wr = 1;
         imm_src = Imm_I;
         alu_src = ALU_SRC_IMM;
         case(funct)
         10'b0000000000 : alu_control  = ALU_ADD;
         10'b0000000010 : alu_control = ALU_SLT;
         10'b0000000011 : alu_control = ALU_SLTU;
         10'b0000000100 : alu_control = ALU_XOR;
         10'b0000000110 : alu_control = ALU_OR;   
         10'b0000000111 : alu_control = ALU_AND;
         10'b0000000001 : alu_control = ALU_SLL;
         10'b0000000101 : alu_control = ALU_SRL;
         10'b0100000101 : alu_control = ALU_SRA;
         default : alu_control = ALU_ADD;
         endcase
         end

    7'b0000011 : begin // Load _ type
    mem_rd = 1 ;
    reg_wr = 1;
    memtoreg = 1;
    imm_src = Imm_I;
    alu_src = ALU_SRC_IMM;
    result_src = RESULT_SRC_MEM;
    case(funct3)
    3'b000 : load_type = LOAD_LB;
    3'b001 : load_type = LOAD_LH;
    3'b010 : load_type = LOAD_LW;
    3'b100 : load_type = LOAD_LBU;
    3'b101 : load_type = LOAD_LHU;
    default : begin
    load_type = LOAD_LW;
    end 
    endcase
    end

    7'b0100011 : begin // Store type 
    mem_wr = 1;
    imm_src = Imm_S;
    alu_src = ALU_SRC_IMM;
    case(funct3)
    3'b000 : store_type = STORE_SB;
    3'b001 : store_type = STORE_SH;
    3'b010 : store_type = STORE_SW;
    default : store_type = STORE_SW;
    endcase
    end

    7'b1100011 : begin // Branch type 
    imm_src = Imm_B;
    alu_src = ALU_SRC_REG;
    reg_wr = 0 ;
    mem_wr = 0 ;
    branch = 1;
    case(funct3)
    3'b000 : begin
             alu_control = ALU_SUB;
             branch_type = BRANCH_BEQ;
             end 

    3'b001 : begin
             alu_control = ALU_SUB ;
             branch_type = BRANCH_BNE;
             end

    3'b100 : begin
             alu_control = ALU_SLT;
             branch_type = BRANCH_BLT;
             end

    3'b101 : begin
             alu_control = ALU_SLT;
             branch_type = BRANCH_BGE;
             end

    3'b110 : begin
             alu_control = ALU_SLTU;
             branch_type = BRANCH_BLTU;
             end

    3'b111 : begin
             alu_control = ALU_SLTU;
             branch_type = BRANCH_BGEU;
             end

     default : begin
             alu_control = ALU_SUB;
             branch_type = BRANCH_BEQ;
             end

               endcase

    end

    7'b0110111 : begin // LUI
    reg_wr = 1;
    imm_src = Imm_U;
    alu_src = ALU_SRC_IMM;
    alu_control = ALU_ADD;
    lui = 1; // instr[19:15] is NOT rs1 for U-type -- force ALU A-operand to 0
    end

    7'b0010111 : begin // AUIPC
    reg_wr = 1;
    result_src = RESULT_SRC_ALU;
    alu_src = ALU_SRC_IMM;
    alu_control = ALU_ADD;
    imm_src = Imm_U;
    auipc = 1; // instr[19:15] is NOT rs1 for U-type -- force ALU A-operand to pc_ex
    end

    7'b1101111 : begin // JAL 
    jal = 1;
    reg_wr  = 1;
    result_src = RESULT_SRC_PC;
    alu_src = ALU_SRC_IMM;
    alu_control = ALU_ADD;
    imm_src = Imm_J;
    end

    7'b1100111 : begin // JALR
    jalr = 1;
    reg_wr = 1;
    imm_src = Imm_I;
    alu_control = ALU_ADD;
    alu_src = ALU_SRC_IMM;
    result_src = RESULT_SRC_PC;
    end


    default : begin
              load_type = LOAD_LW;
              store_type = STORE_SW;
              branch_type = BRANCH_BEQ;
              end 

    endcase   

end

endmodule