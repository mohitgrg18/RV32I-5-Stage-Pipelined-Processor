`timescale 1ns/1ps

module hazard_unit(
    input clk ,
    input rst,
    // EX stage 
    input [4:0]rs1_ex,
    input[4:0]rs2_ex,
    input [4:0]rd_ex,
    // MEM stage 
    input [4:0]rd_mem,
    input reg_wr_mem,
    // WB stage
    input [4:0]rd_wb,   
    input reg_wr_wb,
 
    // load hazard 
    input mem_rd_ex,
    input [4:0]rs1_id,
    input [4:0]rs2_id,
    
    //ccontrol hazard (branch / jump)
    input branch_take_ex,
    input jump_ex,

     // Forwarding output  
    output reg [1:0]forward_AE,
    output reg [1:0]forward_BE,

    // stall output
    output reg stallF,
    output reg stallD,
    output reg flushE,
    output reg  flushD
);

wire lwstall;

always@(*)begin
        forward_AE = 2'b00;
        forward_BE = 2'b00;

    // operand A
    if(reg_wr_mem && (rd_mem != 5'b0) && (rd_mem == rs1_ex))
         forward_AE = 2'b10;
    else if(reg_wr_wb && (rd_wb !=5'b0) && (rd_wb == rs1_ex))
         forward_AE = 2'b01;
    
    // operand B
    if(reg_wr_mem && (rd_mem != 5'b0) && (rd_mem == rs2_ex))
         forward_BE = 2'b10;
    else if(reg_wr_wb && (rd_wb !=5'b0) && (rd_wb == rs2_ex))
         forward_BE = 2'b01;
    
end


assign lwstall = (mem_rd_ex && (rd_ex != 5'b0) && (rd_ex == rs1_id || rd_ex == rs2_id));

assign stallF = lwstall;
assign stallD = lwstall;
assign flushE = lwstall || branch_take_ex || jump_ex;
assign flushD = branch_take_ex || jump_ex;

endmodule 

