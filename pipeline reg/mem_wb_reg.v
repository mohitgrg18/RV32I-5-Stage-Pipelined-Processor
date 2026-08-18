module mem_wb(
    input clk,
    input  rst,
    input [31:0]alu_result_mem,
    input [31:0]read_data_mem,
    input [4:0]rd_mem,
    input reg_wr_mem,
    input [1:0]result_src_mem,
    input [31:0]pc_plus4_mem,

    output reg [31:0]alu_result_wb,
    output reg [31:0]read_data_wb,
    output reg [4:0]rd_wb,
    output reg reg_wr_wb,
    output reg [1:0]result_src_wb,
    output reg [31:0]pc_plus4_wb
);

always@(posedge clk or negedge rst)begin
if(!rst)begin
    alu_result_wb <= 32'b0;
    read_data_wb <= 32'b0;
    rd_wb <= 5'b0;
    reg_wr_wb <= 1'b0;
    result_src_wb <= 2'b0;
    pc_plus4_wb <= 32'b0;
end 

else begin
    alu_result_wb <= alu_result_mem;
    read_data_wb <= read_data_mem;
    rd_wb <= rd_mem;
    reg_wr_wb <= reg_wr_mem;
    result_src_wb <= result_src_mem;
    pc_plus4_wb <= pc_plus4_mem;
end
end

endmodule