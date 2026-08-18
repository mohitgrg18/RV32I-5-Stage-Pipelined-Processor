module id_ex(
    input clk, rst ,

    input [31:0]rd1_id ,
    input [31:0]rd2_id,
    input [31:0]pc_id,
    input[31:0]imm_id,
    input[4:0]rs1_id,
    input[4:0]rs2_id,
    input [4:0]rd_id,
    input [31:0]pc_plus4_id,
    input jal_id,
    input jalr_id,
    input flush,
    // control unit signals
    input  reg_wr_id,
    input mem_rd_id,
    input mem_wr_id,
    input [1:0]result_src_id,
    input branch_id,
    input [3:0]alu_control_id,
    input alu_src_id,
    input [1:0]store_type_id,
    input [2:0]load_type_id,
    input[2:0]branch_type_id,
    input lui_id,
    input auipc_id,

    output reg [31:0]rd1_ex,
    output reg[31:0]rd2_ex,
    output reg[31:0]pc_ex,
    output reg [31:0]imm_ex,
    output reg[4:0]rs1_ex,
    output reg [4:0]rs2_ex,
    output reg [4:0]rd_ex,
    output reg [31:0]pc_plus4_ex,
    output reg jal_ex,
    output reg jalr_ex,
    // control unit signals
    output reg reg_wr_ex,
    output reg mem_rd_ex,
    output reg mem_wr_ex,
    output reg [1:0]result_src_ex,
    output reg branch_ex,
    output reg [3:0]alu_control_ex,
    output reg alu_src_ex,
    output reg [1:0]store_type_ex,
    output reg [2:0]load_type_ex,
    output reg [2:0]branch_type_ex,
    output reg lui_ex,
    output reg auipc_ex

);

always@(posedge clk or negedge rst)begin
if(!rst)begin
rd1_ex <= 32'b0;
rd2_ex <= 32'b0;
pc_ex <= 32'b0;
imm_ex <= 32'b0;
rs1_ex <= 5'b0;
rs2_ex <= 5'b0;
rd_ex <= 5'b0;
pc_plus4_ex <= 32'b0;
jal_ex <= 1'b0;
jalr_ex <= 1'b0;

reg_wr_ex <= 1'b0;
mem_rd_ex <= 1'b0;
mem_wr_ex <= 1'b0;
result_src_ex <= 2'b0;
branch_ex <= 1'b0;
alu_control_ex <= 4'b0;
alu_src_ex <= 1'b0;
store_type_ex <= 2'b0;
load_type_ex <= 3'b0;
branch_type_ex <= 3'b0;
lui_ex <= 1'b0;
auipc_ex <= 1'b0;
end

else if(flush)begin
 rd1_ex <= 32'b0;
rd2_ex <= 32'b0;
pc_ex <= 32'b0;
imm_ex <= 32'b0;
rs1_ex <= 5'b0;
rs2_ex <= 5'b0;
rd_ex <= 5'b0;
pc_plus4_ex <= 32'b0;
jal_ex <= 1'b0;
jalr_ex <= 1'b0;

reg_wr_ex <= 1'b0;
mem_rd_ex <= 1'b0;
mem_wr_ex <= 1'b0;
result_src_ex <= 2'b0;
branch_ex <= 1'b0;
alu_control_ex <= 4'b0;
alu_src_ex <= 1'b0;
store_type_ex <= 2'b0;
load_type_ex <= 3'b0;
branch_type_ex <= 3'b0;
lui_ex <= 1'b0;
auipc_ex <= 1'b0;
end

else begin
rd1_ex <= rd1_id;
rd2_ex <= rd2_id;
pc_ex <= pc_id;
imm_ex <= imm_id;
rs1_ex <= rs1_id;
rs2_ex <= rs2_id;
rd_ex <= rd_id;
pc_plus4_ex <= pc_plus4_id;
jal_ex <= jal_id;
jalr_ex <= jalr_id;

reg_wr_ex <= reg_wr_id;
mem_rd_ex <= mem_rd_id;
mem_wr_ex <= mem_wr_id;
result_src_ex <= result_src_id;
branch_ex <= branch_id;
alu_control_ex <= alu_control_id;
alu_src_ex <= alu_src_id;
store_type_ex <= store_type_id;
load_type_ex <= load_type_id;
branch_type_ex <= branch_type_id;
lui_ex <= lui_id;
auipc_ex <= auipc_id;
end
end

endmodule