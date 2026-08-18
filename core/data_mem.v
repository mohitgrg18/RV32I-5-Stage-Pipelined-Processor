`timescale 1ns / 1ps


module data_memory #(
       parameter MEM_SIZE = 1024
)
(
    input clk,
    input mem_rd,
    input mem_wr,
    input [31:0]addr,
    input [31:0]wr_data,
    input [1:0]store_type,
    input [2:0]load_type,
    output reg [31:0]rd_data
);

localparam STORE_SW = 2'b00,
           STORE_SH = 2'b01,
           STORE_SB = 2'b10;

localparam LOAD_LW = 3'b000,
           LOAD_LB = 3'b001,
           LOAD_LH = 3'b010,
           LOAD_LBU = 3'b011,
           LOAD_LHU = 3'b100;



reg [7:0]mem[0:MEM_SIZE-1]; // 1KB memory
reg[3:0]wr_stb;

localparam ADDR_WIDTH = $clog2(MEM_SIZE);

wire[ADDR_WIDTH-1 :0]mem_addr;
assign mem_addr = addr[ADDR_WIDTH-1:0];

always@(*)begin
   rd_data = 32'b0;
if(mem_rd)begin
     case(load_type)
        LOAD_LW : rd_data = {mem[mem_addr+3],mem[mem_addr+2],mem[mem_addr+1],mem[mem_addr]};
        LOAD_LB : rd_data = {{24{mem[mem_addr][7]}},mem[mem_addr]};
        LOAD_LH : rd_data = {{16{mem[mem_addr+1][7]}},mem[mem_addr+1],mem[mem_addr]};
        LOAD_LBU : rd_data = {24'b0,mem[mem_addr]};
        LOAD_LHU : rd_data = {16'b0,mem[mem_addr+1][7:0],mem[mem_addr][7:0]};        
        default : rd_data = 32'b0;
        endcase
end
end

always@(*)begin
case(store_type)
    STORE_SW : wr_stb = 4'b1111;
    STORE_SH : wr_stb = 4'b0011;
    STORE_SB : wr_stb = 4'b0001;
    default : wr_stb = 4'b0000;
endcase
end

always@(posedge clk)begin
if(mem_wr)begin
    if(wr_stb[0]) 
         mem[mem_addr] <= wr_data[7:0];
    if(wr_stb[1])
        mem[mem_addr+1] <= wr_data[15:8];
    if(wr_stb[2])
       mem[mem_addr+2] <= wr_data[23:16];
    if(wr_stb[3])
        mem[mem_addr+3] <= wr_data [31:24];
          end
        end

endmodule 


