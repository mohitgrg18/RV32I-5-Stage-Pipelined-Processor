`timescale 1ns/1ps

module top_pipeline(
    input clk,
    input rst
);

reg[31:0]pc;
wire [31:0]pc_nxt;
wire[31:0]pc_plus4;

assign pc_plus4 = pc + 32'd4;


always@(posedge clk or negedge rst)begin
if(!rst)
  pc <= 32'b0;
else if(!stallF)
pc <= pc_nxt;
end

// instruction fetch 
wire[31:0]instr;
ins_mem u_imem(
    .addr(pc),
    .instr(instr)
);


// if_id pipeline reg 
wire[31:0]instrF;
wire[31:0]pcF;
wire[31:0]pc_plus4F;
wire[31:0]instrD;
wire[31:0]pcD;
wire[31:0]pc_plus4D;

if_id u_if_id(
    .clk(clk),
    .rst(rst),
    .instrF(instr),
    .pc_plus4F(pc_plus4),
    .stall(stallD),
    .flush(flushD),
    .pcF(pc),
    .instrD(instrD),
    .pc_plus4D(pc_plus4D),
    .pcD(pcD)
);


wire[6:0]opcode = instrD[6:0];
wire[4:0]rs1 = instrD[19:15];
wire[4:0]rs2 = instrD[24:20];
wire[4:0]rd = instrD[11:7];
wire [31:0]RD1,RD2,WD3;
// instruction decode
reg_file u_regfile(
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd_wb),
    .regwrite (reg_wr_wb),
    .WD3(result_wb),
    .RD1(RD1),
    .RD2(RD2)
);


// control unit 
wire[2:0]funct3 = instrD[14:12];
wire[6:0]funct7 = instrD[31:25];
wire[2:0]load_type;
wire[1:0]store_type;
wire[1:0]result_src;
wire[3:0]alu_control;
wire[2:0]branch_type;
wire [2:0]imm_src;
wire reg_wr , mem_rd , mem_wr , memtoreg , alu_src, branch ;
// wire jump;
wire jal;
wire jalr;
wire lui;
wire auipc;

control_unit u_ctrl(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .reg_wr(reg_wr),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .branch(branch),
    .jal(jal),
    .jalr(jalr),
    .memtoreg(memtoreg),
    .alu_src(alu_src),
    .imm_src(imm_src),
    .alu_control(alu_control),
    .load_type(load_type),
    .store_type(store_type),
    .branch_type(branch_type),
    .result_src(result_src),
    .lui(lui),
    .auipc(auipc)
);


// immediate extender
wire[31:0]imm_ext;
imm_extend u_imm_ext(
    .instr(instrD),
    .imm_src(imm_src),
    .imm_ext(imm_ext)
);

// id_ex pipeline reg 
wire[31:0]rd1_ex, rd2_ex, pc_ex, imm_ex;
wire[4:0]rs1_ex, rs2_ex, rd_ex;
wire[31:0]pc_plus4_ex ;
wire reg_wr_ex, mem_rd_ex, mem_wr_ex, alu_src_ex, branch_ex;
wire[1:0]result_src_ex, store_type_ex;
wire[2:0]load_type_ex, branch_type_ex;
wire[3:0]alu_control_ex;
wire jal_ex;
wire jalr_ex;
wire lui_ex;
wire auipc_ex;


id_ex u_id_ex(
    .clk(clk),
    .rst(rst),
    .rd1_id(RD1),
    .rd2_id(RD2),
    .pc_id(pcD),
    .imm_id(imm_ext),
    .rs1_id(rs1),
    .rs2_id(rs2),
    .rd_id(rd),
    .pc_plus4_id(pc_plus4D),
    .jal_id(jal),
    .jalr_id(jalr),
    .flush(flushE),
    .reg_wr_id(reg_wr),
    .mem_rd_id(mem_rd),
    .mem_wr_id(mem_wr),
    .result_src_id(result_src),
    .branch_id(branch),
    .alu_control_id(alu_control),
    .alu_src_id(alu_src),
    .store_type_id(store_type),
    .load_type_id(load_type),
    .branch_type_id(branch_type),
    .lui_id(lui),
    .auipc_id(auipc),

    .rd1_ex(rd1_ex),
    .rd2_ex(rd2_ex),
    .pc_ex(pc_ex),
    .imm_ex(imm_ex),
    .rs1_ex(rs1_ex),
    .rs2_ex(rs2_ex),
    .rd_ex(rd_ex),
    .pc_plus4_ex(pc_plus4_ex),
    .jal_ex(jal_ex),
    .jalr_ex(jalr_ex),
    .reg_wr_ex(reg_wr_ex),
    .mem_rd_ex(mem_rd_ex),
    .mem_wr_ex(mem_wr_ex),
    .result_src_ex(result_src_ex),
    .branch_ex(branch_ex),
    .alu_control_ex(alu_control_ex),
    .alu_src_ex(alu_src_ex),
    .store_type_ex(store_type_ex),
    .load_type_ex(load_type_ex),
    .branch_type_ex(branch_type_ex),
    .lui_ex(lui_ex),
    .auipc_ex(auipc_ex)
);

// alu 
reg[31:0]alu_A;

always@(*)begin
  // U-type (LUI/AUIPC): instr[19:15] is NOT rs1, it's part of the immediate,
  // so rd1_ex/forwarding must never be used as the A-operand for these.
  if (lui_ex)
     alu_A = 32'b0;
  else if (auipc_ex)
     alu_A = pc_ex;
  else begin
  case(forward_AE)
     2'b00 : alu_A = rd1_ex;
     2'b10 : alu_A = alu_result_mem;
     2'b01 : alu_A = result_wb;
     default : alu_A = rd1_ex;
     endcase
     end
     end

reg[31:0]alu_mux_B;

always@(*)begin
  case(forward_BE)
  2'b00 : alu_mux_B = rd2_ex;
  2'b10 : alu_mux_B = alu_result_mem;
  2'b01 : alu_mux_B = result_wb;
  default : alu_mux_B = rd2_ex;
  endcase
end

wire[31:0]alu_B;
assign alu_B = (alu_src_ex) ? imm_ex : alu_mux_B;

wire[31:0]alu_result_ex;
wire zero;
alu u_alu(
    .A(alu_A),
    .B(alu_B),
    .alu_control(alu_control_ex),
    .alu_result(alu_result_ex),
    .zero(zero)
);


// ex_mem pipeline register 
wire[31:0]alu_result_mem;
wire[31:0]rd2_mem;
wire[4:0]rd_mem;
wire reg_wr_mem;
wire mem_rd_mem;
wire mem_wr_mem;
wire[1:0]result_src_mem;
wire[1:0]store_type_mem;
wire[2:0]load_type_mem;
wire take_branch_mem;
wire[31:0]pc_plus4_mem;

ex_mem u_ex_mem(
    .clk(clk),
    .rst(rst),
    .alu_result_ex(alu_result_ex),
    .rd2_ex(alu_mux_B),
    .rd_ex(rd_ex),
    .reg_wr_ex(reg_wr_ex),
    .mem_rd_ex(mem_rd_ex),
    .mem_wr_ex(mem_wr_ex),
    .result_src_ex(result_src_ex),
    .store_type_ex(store_type_ex),
    .load_type_ex(load_type_ex),
    .take_branch_ex(take_branch_ex),
    .pc_plus4_ex(pc_plus4_ex),
    .alu_result_mem(alu_result_mem),
    .rd2_mem(rd2_mem),
    .rd_mem(rd_mem),
    .reg_wr_mem(reg_wr_mem),
    .mem_rd_mem(mem_rd_mem),
    .mem_wr_mem(mem_wr_mem),
    .result_src_mem(result_src_mem),
    .store_type_mem(store_type_mem),
    .load_type_mem(load_type_mem),
    .take_branch_mem(take_branch_mem),
    .pc_plus4_mem(pc_plus4_mem)

);

wire[31:0]pc_target_ex;
assign pc_target_ex = pc_ex + imm_ex;

reg take_branch_ex;
always@(*)begin
  if (!branch_ex)
      take_branch_ex = 1'b0;
  else begin
  case(branch_type_ex)
  3'b000 : take_branch_ex = zero ; // BEQ
  3'b001 : take_branch_ex = ~zero; // BNQ
  3'b010 : take_branch_ex = alu_result_ex[0]; // BLT
  3'b100 : take_branch_ex = ~alu_result_ex[0]; // BGE
  3'b101 : take_branch_ex = alu_result_ex[0]; // BLTU
  3'b110 : take_branch_ex = ~alu_result_ex[0]; //BGEU
  default : take_branch_ex = 1'b0;
  endcase
  end
  end

wire[31:0]jalr_target;
assign jalr_target = {alu_result_ex[31:1],1'b0};



assign pc_nxt =
      (jalr_ex)? jalr_target : 
      (jal_ex)? pc_target_ex :
      (branch_ex && take_branch_ex)? pc_target_ex : 
          pc_plus4 ;



// data memory 
wire[31:0]rd_data_mem;

data_memory #(
    .MEM_SIZE(1024)
)u_data_mem(
    .clk(clk),
    .mem_rd(mem_rd_mem),
    .mem_wr(mem_wr_mem),
    .addr(alu_result_mem),
    .wr_data(rd2_mem),
    .store_type(store_type_mem),
    .load_type(load_type_mem),
    .rd_data(rd_data_mem)
);


// memory writeback pipeline register
wire[31:0]alu_result_wb;
wire[31:0]rd_data_wb;
wire[4:0]rd_wb;
wire reg_wr_wb;
wire[1:0]result_src_wb;
wire[31:0]pc_plus4_wb;

mem_wb u_mem_wb(
    .clk(clk),
    .rst(rst),
    .alu_result_mem(alu_result_mem),
    .read_data_mem(rd_data_mem),
    .rd_mem(rd_mem),
    .reg_wr_mem(reg_wr_mem),
    .result_src_mem(result_src_mem),
    .pc_plus4_mem(pc_plus4_mem),
    .alu_result_wb(alu_result_wb),
    .read_data_wb(rd_data_wb),
    .rd_wb(rd_wb),
    .reg_wr_wb(reg_wr_wb),
    .result_src_wb(result_src_wb),
    .pc_plus4_wb(pc_plus4_wb)

);
reg[31:0]result_wb;
always@(*)begin
  case(result_src_wb)
  2'b00 : result_wb = rd_data_wb;
  2'b01 : result_wb = alu_result_wb;
  2'b10 : result_wb = pc_plus4_wb;
  default : result_wb = alu_result_wb;
  endcase
end


// Hazard Detection unit 
wire[1:0]forward_AE;
wire[1:0]forward_BE;
wire stallF;
wire stallD;
wire flushE;
wire flushD;

wire jump_ex;
assign jump_ex = jal_ex | jalr_ex;

hazard_unit u_hazard(
    .clk(clk),
    .rst(rst),
    .rs1_ex(rs1_ex),
    .rs2_ex(rs2_ex),
    .rd_ex(rd_ex),
    .rd_mem(rd_mem),
    .reg_wr_mem(reg_wr_mem),
    .rd_wb(rd_wb),
    .reg_wr_wb(reg_wr_wb),
    .mem_rd_ex(mem_rd_ex),
    .rs1_id(rs1),
    .rs2_id(rs2),
    .branch_take_ex(take_branch_ex),
    .jump_ex(jump_ex),
    .forward_AE(forward_AE),
    .forward_BE(forward_BE),
    .stallF(stallF),
    .stallD(stallD),
    .flushE(flushE),
    .flushD(flushD)
);

endmodule