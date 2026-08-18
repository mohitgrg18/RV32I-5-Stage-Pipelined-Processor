module ex_mem(
    input clk ,rst,
    input [31:0]alu_result_ex,
    input [31:0]rd2_ex,
    input [4:0]rd_ex,
    
    input reg_wr_ex,
    input mem_rd_ex,
    input mem_wr_ex,
    input [1:0]result_src_ex,
    input [1:0]store_type_ex,
    input [2:0]load_type_ex,

    input take_branch_ex,
    input[31:0]pc_plus4_ex,

    output reg [31:0]alu_result_mem,
    output reg [31:0]rd2_mem,
    output reg[4:0]rd_mem,
    output reg reg_wr_mem,
    output reg mem_rd_mem,
    output reg mem_wr_mem,
    output reg[1:0]result_src_mem,
    output reg[1:0]store_type_mem,
    output reg[2:0]load_type_mem,
    output reg take_branch_mem,
    output reg[31:0]pc_plus4_mem 
    );


always@(posedge clk or negedge rst)begin
if(!rst)begin
    alu_result_mem <= 32'b0;
    rd2_mem <= 32'b0;
    rd_mem <= 5'b0;
    reg_wr_mem <= 1'b0;
    mem_rd_mem <= 1'b0;
    mem_wr_mem <= 1'b0;
    result_src_mem <= 2'b0;
    store_type_mem <= 2'b0;
    load_type_mem <= 3'b0;
    take_branch_mem <= 1'b0;
    pc_plus4_mem <= 32'b0;
end 

else begin
    alu_result_mem <= alu_result_ex;
    rd2_mem <= rd2_ex;
    rd_mem <= rd_ex;
    reg_wr_mem <= reg_wr_ex;
    mem_rd_mem <= mem_rd_ex;
    mem_wr_mem <= mem_wr_ex;
    result_src_mem <= result_src_ex;
    store_type_mem <= store_type_ex;
    load_type_mem <= load_type_ex;
    take_branch_mem <= take_branch_ex;
    pc_plus4_mem <= pc_plus4_ex;
end
end
endmodule    