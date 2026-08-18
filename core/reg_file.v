`timescale 1ns / 1ps

module reg_file(
    input clk , rst ,
    input [4:0]rs1,
    input [4:0]rs2,
    input [4:0]rd,
    input regwrite,
    input [31:0]WD3,

    output [31:0]RD1,
    output [31:0]RD2

);

reg [31:0]reg_arr[0:31];
integer i;

always@(posedge clk or negedge rst)begin
if(!rst)
begin
  for(i=0;i<32;i=i+1)
  reg_arr[i] <= 32'b0;
  end

else
begin
  if(regwrite && (rd != 5'd0))
     reg_arr[rd] <= WD3;
     end
end



// write-first bypass: forward the value being written this cycle if the
// read address matches the write address (fixes RAW hazards with an
// exact 3-instruction gap, where WB and ID land on the same clock edge)
assign RD1 = (rs1 == 5'd0) ? 32'b0 :
             (regwrite && (rd == rs1) && (rd != 5'd0)) ? WD3 : reg_arr[rs1];
assign RD2 = (rs2 == 5'd0) ? 32'b0 :
             (regwrite && (rd == rs2) && (rd != 5'd0)) ? WD3 : reg_arr[rs2];

endmodule