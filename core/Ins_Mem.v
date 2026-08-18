`timescale 1ns / 1ps

module ins_mem(
    input [31:0]addr,
    output reg [31:0]instr
);

reg [31:0]mem[0:255];

always@(*)begin
case(addr[9:2])
    // ---- base ALU / load-store sanity (from the original sample program) ----
    8'd0  : instr = 32'h00500093 ; // addi x1,  x0, 5
    8'd1  : instr = 32'h00A00113 ; // addi x2,  x0, 10
    8'd2  : instr = 32'h002081B3 ; // add  x3,  x1, x2
    8'd3  : instr = 32'h01400213 ; // addi x4,  x0, 20
    8'd4  : instr = 32'h00302023 ; // sw   x3,  0(x0)
    8'd5  : instr = 32'h00002283 ; // lw   x5,  0(x0)

    // ---- byte / halfword load-store variants ----
    8'd6  : instr = 32'hFFF00313 ; // addi x6,  x0, -1        (x6 = 0xFFFFFFFF)
    8'd7  : instr = 32'h00600223 ; // sb   x6,  4(x0)         (mem[4] = 0xFF)
    8'd8  : instr = 32'h00400383 ; // lb   x7,  4(x0)         (x7 = sign-ext -1)
    8'd9  : instr = 32'h00404403 ; // lbu  x8,  4(x0)         (x8 = 255)
    8'd10 : instr = 32'h00601423 ; // sh   x6,  8(x0)         (mem[8:9] = 0xFFFF)
    8'd11 : instr = 32'h00801483 ; // lh   x9,  8(x0)         (x9 = sign-ext -1)
    8'd12 : instr = 32'h00805503 ; // lhu  x10, 8(x0)         (x10 = 65535)

    // ---- branches: each "taken" branch skips one addi x?,999 filler ----
    8'd13 : instr = 32'h00108463 ; // beq  x1, x1, +8   -> taken
    8'd14 : instr = 32'h3E700593 ; // addi x11, x0, 999 -> skipped
    8'd15 : instr = 32'h06F00593 ; // addi x11, x0, 111 -> x11 = 111

    8'd16 : instr = 32'h00209463 ; // bne  x1, x2, +8   -> taken
    8'd17 : instr = 32'h3E700613 ; // addi x12, x0, 999 -> skipped
    8'd18 : instr = 32'h0DE00613 ; // addi x12, x0, 222 -> x12 = 222

    8'd19 : instr = 32'h00114463 ; // blt  x2, x1, +8   -> NOT taken (10<5 false)
    8'd20 : instr = 32'h14D00693 ; // addi x13, x0, 333 -> x13 = 333 (falls through)

    8'd21 : instr = 32'h0020C463 ; // blt  x1, x2, +8   -> taken (5<10 true)
    8'd22 : instr = 32'h3E700713 ; // addi x14, x0, 999 -> skipped
    8'd23 : instr = 32'h1BC00713 ; // addi x14, x0, 444 -> x14 = 444

    8'd24 : instr = 32'h00115463 ; // bge  x2, x1, +8   -> taken (10>=5 true)
    8'd25 : instr = 32'h3E700793 ; // addi x15, x0, 999 -> skipped
    8'd26 : instr = 32'h22B00793 ; // addi x15, x0, 555 -> x15 = 555

    8'd27 : instr = 32'h0020E463 ; // bltu x1, x2, +8   -> taken (5<10 true)
    8'd28 : instr = 32'h3E700813 ; // addi x16, x0, 999 -> skipped
    8'd29 : instr = 32'h29A00813 ; // addi x16, x0, 666 -> x16 = 666

    8'd30 : instr = 32'h00117463 ; // bgeu x2, x1, +8   -> taken (10>=5 true)
    8'd31 : instr = 32'h3E700893 ; // addi x17, x0, 999 -> skipped
    8'd32 : instr = 32'h30900893 ; // addi x17, x0, 777 -> x17 = 777

    // ---- jumps ----
    8'd33 : instr = 32'h0080096F ; // jal  x18, +8      -> x18 = link (addr 136), skip filler
    8'd34 : instr = 32'h3E700993 ; // addi x19, x0, 999 -> skipped
    8'd35 : instr = 32'h37800993 ; // addi x19, x0, 888 -> x19 = 888

    8'd36 : instr = 32'h09800A67 ; // jalr x20, x0, 152 -> x20 = link (addr 148), jump to 152
    8'd37 : instr = 32'h3E700A93 ; // addi x21, x0, 999 -> skipped
    8'd38 : instr = 32'h0DE00A93 ; // addi x21, x0, 222 -> x21 = 222

    // ---- extra ALU op-code coverage (R-type variants) + U-type + hazard stress ----
    8'd39 : instr = 32'h00C00B13 ; // addi x22,x0,12
    8'd40 : instr = 32'h00700B93 ; // addi x23,x0,7
    8'd41 : instr = 32'h417B0C33 ; // sub  x24,x22,x23        -> x24 = 5
    8'd42 : instr = 32'h017B7C33 ; // and  x24,x22,x23        -> x24 = 4
    8'd43 : instr = 32'h017B6C33 ; // or   x24,x22,x23        -> x24 = 15
    8'd44 : instr = 32'h017B4C33 ; // xor  x24,x22,x23        -> x24 = 11
    8'd45 : instr = 32'h00300C93 ; // addi x25,x0,3
    8'd46 : instr = 32'h019B9C33 ; // sll  x24,x23,x25        -> x24 = 56
    8'd47 : instr = 32'h019B5C33 ; // srl  x24,x22,x25        -> x24 = 1
    8'd48 : instr = 32'hFF800C13 ; // addi x24,x0,-8
    8'd49 : instr = 32'h419C5C33 ; // sra  x24,x24,x25        -> x24 = -1 (EX-EX forward test)
    8'd50 : instr = 32'h017CACB3 ; // slt  x25,x25,x23        -> x25 = 1
    8'd51 : instr = 32'h016BBCB3 ; // sltu x25,x23,x22        -> x25 = 1
    8'd52 : instr = 32'h12345D37 ; // lui  x26,0x12345        -> x26 = 0x12345000
    8'd53 : instr = 32'h00001D97 ; // auipc x27,0x1           -> x27 = pc(212)+0x1000 = 0x10D4
    8'd54 : instr = 32'h01802A23 ; // sw   x24,20(x0)         -> mem[20..23] = 0xFFFFFFFF
    8'd55 : instr = 32'h01402E03 ; // lw   x28,20(x0)         -> x28 = 0xFFFFFFFF
    8'd56 : instr = 32'h000E0EB3 ; // add  x29,x28,x0         -> x29 = 0xFFFFFFFF (load-use stall test)

    default : instr = 32'h00000013; // addi x0, x0, 0 (NOP)
        endcase
  
end

endmodule