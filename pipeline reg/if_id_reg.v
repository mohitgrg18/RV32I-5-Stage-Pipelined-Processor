module if_id (
    input clk ,rst,
    input [31:0]instrF,
    input [31:0]pcF,
    input[31:0]pc_plus4F,
    input stall,
    input flush,

    output reg [31:0]instrD,
    output reg [31:0]pcD,
    output reg [31:0]pc_plus4D

);

always@(posedge clk or negedge rst)begin
  if(!rst)begin
  instrD <= 32'b0;
  pcD <= 32'b0;
  pc_plus4D <= 32'b0;
  end
  else if(flush)begin
    instrD <= 32'b0;
    pcD <= 32'b0;
    pc_plus4D <= 32'b0;
  end
 else if(!stall) begin
  instrD <= instrF;
  pcD <= pcF;
  pc_plus4D <= pc_plus4F;
end
end 
endmodule