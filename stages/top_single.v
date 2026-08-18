`timescale 1ns / 1ps
//======================================================================
// riscv_top.v
// Single-cycle RV32I top module wiring:
//   Ins_Mem, control_unit, reg_file, Imm_extend, alu, data_memory
//======================================================================
module riscv_top(
    input clk,
    input rst          // active-low, matches reg_file's "negedge rst"
);

    //------------------------------------------------------------
    // Program counter
    //------------------------------------------------------------
    reg  [31:0] PC;
    wire [31:0] PCNext, PCPlus4, PCTarget;

    assign PCPlus4  = PC + 32'd4;
    assign PCTarget = PC + imm_ext;      // branch / JAL target (PC-relative)

    always @(posedge clk or negedge rst) begin
        if (!rst) PC <= 32'b0;
        else      PC <= PCNext;
    end

    //------------------------------------------------------------
    // Instruction memory / fetch
    //------------------------------------------------------------
    wire [31:0] instr;
    Ins_Mem u_imem (
        .addr  (PC),
        .instr (instr)
    );

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    wire is_jalr = (opcode == 7'b1100111);

    //------------------------------------------------------------
    // Control unit
    //------------------------------------------------------------
    wire        reg_wr, mem_rd, mem_wr, Branch, jump, memtoreg, Alu_src;
    wire [2:0]  Imm_src;
    wire [3:0]  Alu_control;
    wire [2:0]  Load_type;
    wire [1:0]  Store_type;
    wire [2:0]  Branch_type;
    wire [1:0]  Result_src;

    control_unit u_ctrl (
        .opcode      (opcode),
        .funct7      (funct7),
        .funct3      (funct3),
        .reg_wr      (reg_wr),
        .mem_rd      (mem_rd),
        .mem_wr      (mem_wr),
        .Branch      (Branch),
        .jump        (jump),
        .memtoreg    (memtoreg),
        .Alu_src     (Alu_src),
        .Imm_src     (Imm_src),
        .Alu_control (Alu_control),
        .Load_type   (Load_type),
        .Store_type  (Store_type),
        .Branch_type (Branch_type),
        .Result_src  (Result_src)
    );

    //------------------------------------------------------------
    // Register file
    //------------------------------------------------------------
    wire [31:0] RD1, RD2, WD3;

    reg_file u_rf (
        .clk      (clk),
        .rst      (rst),
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (rd),
        .regwrite (reg_wr),
        .WD3      (WD3),
        .RD1      (RD1),
        .RD2      (RD2)
    );

    //------------------------------------------------------------
    // Immediate generator
    //------------------------------------------------------------
    wire [31:0] imm_ext;

    Imm_extend u_ext (
        .instr   (instr),
        .imm_src (Imm_src),
        .imm_ext (imm_ext)
    );

    //------------------------------------------------------------
    // ALU
    //------------------------------------------------------------
    wire [31:0] alu_B = Alu_src ? imm_ext : RD2;
    wire [31:0] alu_result;
    wire        zero;

    alu u_alu (
        .A            (RD1),
        .B            (alu_B),
        .alu_control  (Alu_control),
        .alu_result   (alu_result),
        .zero         (zero)
    );

    //------------------------------------------------------------
    // Data memory
    //------------------------------------------------------------
    wire [31:0] rd_data;

    data_memory u_dmem (
        .clk        (clk),
        .mem_rd     (mem_rd),
        .mem_wr     (mem_wr),
        .addr       (alu_result),
        .wr_data    (RD2),
        .store_type (Store_type),
        .load_type  (Load_type),
        .rd_data    (rd_data)
    );

    //------------------------------------------------------------
    // Branch resolution
    //   BEQ/BNE  -> based on ALU "zero" (ALU does A - B)
    //   BLT/BLTU -> based on ALU result bit0 (ALU does SLT/SLTU)
    //   BGE/BGEU -> inverse of the SLT/SLTU result
    //------------------------------------------------------------
    reg branch_taken;
    always @(*) begin
        case (Branch_type)
            3'b000 : branch_taken = zero;            // BEQ
            3'b001 : branch_taken = ~zero;           // BNE
            3'b010 : branch_taken = alu_result[0];   // BLT
            3'b100 : branch_taken = ~alu_result[0];  // BGE
            3'b101 : branch_taken = alu_result[0];   // BLTU
            3'b110 : branch_taken = ~alu_result[0];  // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    //------------------------------------------------------------
    // Next-PC mux
    //   JALR target = (RD1 + imm) with LSB cleared -> that's alu_result here
    //   JAL  target = PC + imm                     -> PCTarget
    //   taken branch = PC + imm                    -> PCTarget
    //   otherwise    = PC + 4
    //------------------------------------------------------------
    assign PCNext = jump               ? (is_jalr ? {alu_result[31:1], 1'b0} : PCTarget) :
                    (Branch & branch_taken) ? PCTarget :
                                              PCPlus4;

    //------------------------------------------------------------
    // Register write-back mux
    //   00 -> data memory, 01 -> ALU result, 10 -> PC+4 (link)
    //------------------------------------------------------------
    assign WD3 = (Result_src == 2'b00) ? rd_data   :
                 (Result_src == 2'b10) ? PCPlus4   :
                                          alu_result;

endmodule