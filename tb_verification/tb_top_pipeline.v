`timescale 1ns / 1ps
//======================================================================
// Self-checking testbench for top_pipeline (5-stage pipelined RV32I)
//
// Strategy: watch the register-file write port (rd_wb / reg_wr_wb /
// result_wb) every cycle and compare, IN PROGRAM ORDER, against a
// golden queue of expected (rd, value, mnemonic) results. Because
// squashed/flushed instructions never assert reg_wr_wb, this
// automatically self-adjusts around taken branches/jumps -- no need
// to hand-track pipeline bubbles.
//
// Also does direct checks of data memory contents for store
// instructions (sw/sh/sb) since those never write the register file.
//======================================================================

module tb_top_pipeline;

reg clk;
reg rst;

top_pipeline dut(.clk(clk), .rst(rst));

// 100MHz clock
always #5 clk = ~clk;

//----------------------------------------------------------------
// Golden scoreboard: expected register writes, IN PROGRAM ORDER
//----------------------------------------------------------------
localparam NUM_EXPECTED = 38;
reg [4:0]  exp_rd   [0:NUM_EXPECTED-1];
reg [31:0] exp_val  [0:NUM_EXPECTED-1];
reg [255:0] exp_name [0:NUM_EXPECTED-1]; // ASCII label, up to 32 chars

integer ptr;
integer pass_cnt, fail_cnt;

task add_exp;
    input [4:0] rd;
    input [31:0] val;
    input [255:0] name;
    begin
        exp_rd[ptr]   = rd;
        exp_val[ptr]  = val;
        exp_name[ptr] = name;
        ptr = ptr + 1;
    end
endtask

integer i;
initial begin
    ptr = 0;
    // ---- base ALU / load-store sanity ----
    add_exp(1,  32'd5,          "addi x1,x0,5");
    add_exp(2,  32'd10,         "addi x2,x0,10");
    add_exp(3,  32'd15,         "add  x3,x1,x2");
    add_exp(4,  32'd20,         "addi x4,x0,20");
    add_exp(5,  32'd15,         "lw   x5,0(x0)");
    // ---- byte / halfword load-store variants ----
    add_exp(6,  32'hFFFFFFFF,   "addi x6,x0,-1");
    add_exp(7,  32'hFFFFFFFF,   "lb   x7,4(x0)  (sign-ext)");
    add_exp(8,  32'h000000FF,   "lbu  x8,4(x0)  (zero-ext)");
    add_exp(9,  32'hFFFFFFFF,   "lh   x9,8(x0)  (sign-ext)");
    add_exp(10, 32'h0000FFFF,   "lhu  x10,8(x0) (zero-ext)");
    // ---- branches ----
    add_exp(11, 32'd111,        "beq  taken  -> x11=111");
    add_exp(12, 32'd222,        "bne  taken  -> x12=222");
    add_exp(13, 32'd333,        "blt  NOT taken -> x13=333 (fallthrough)");
    add_exp(14, 32'd444,        "blt  taken  -> x14=444");
    add_exp(15, 32'd555,        "bge  taken  -> x15=555");
    add_exp(16, 32'd666,        "bltu taken  -> x16=666");
    add_exp(17, 32'd777,        "bgeu taken  -> x17=777");
    // ---- jumps ----
    add_exp(18, 32'd136,        "jal  x18,+8 (link = pc+4)");
    add_exp(19, 32'd888,        "addi x19,x0,888 (after jal)");
    add_exp(20, 32'd148,        "jalr x20 (link = pc+4)");
    add_exp(21, 32'd222,        "addi x21,x0,222 (after jalr)");
    // ---- remaining R-type ALU ops ----
    add_exp(22, 32'd12,         "addi x22,x0,12");
    add_exp(23, 32'd7,          "addi x23,x0,7");
    add_exp(24, 32'd5,          "sub  x24,x22,x23");
    add_exp(24, 32'd4,          "and  x24,x22,x23");
    add_exp(24, 32'd15,         "or   x24,x22,x23");
    add_exp(24, 32'd11,         "xor  x24,x22,x23");
    add_exp(25, 32'd3,          "addi x25,x0,3");
    add_exp(24, 32'd56,         "sll  x24,x23,x25");
    add_exp(24, 32'd1,          "srl  x24,x22,x25");
    add_exp(24, 32'hFFFFFFF8,   "addi x24,x0,-8");
    add_exp(24, 32'hFFFFFFFF,   "sra  x24,x24,x25 (EX-EX fwd)");
    add_exp(25, 32'd1,          "slt  x25,x25,x23");
    add_exp(25, 32'd1,          "sltu x25,x23,x22");
    add_exp(26, 32'h12345000,   "lui  x26,0x12345");
    add_exp(27, 32'h000010D4,   "auipc x27,0x1");
    add_exp(28, 32'hFFFFFFFF,   "lw   x28,20(x0) (load-use)");
    add_exp(29, 32'hFFFFFFFF,   "add  x29,x28,x0 (load-use stall)");
end

//----------------------------------------------------------------
// Scoreboard checker: sample WB stage every clock edge
//----------------------------------------------------------------
integer chk_idx;
initial chk_idx = 0;

always @(posedge clk) begin
    #1; // let combinational logic settle after the edge
    if (rst && dut.reg_wr_wb && (dut.rd_wb != 5'd0) && chk_idx < NUM_EXPECTED) begin
        if (dut.rd_wb === exp_rd[chk_idx] && dut.result_wb === exp_val[chk_idx]) begin
            pass_cnt = pass_cnt + 1;
            $display("[PASS] #%0d %-40s x%0d = 0x%08h (%0d)",
                      chk_idx+1, exp_name[chk_idx], dut.rd_wb, dut.result_wb, $signed(dut.result_wb));
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("[FAIL] #%0d %-40s expected x%0d=0x%08h got x%0d=0x%08h",
                      chk_idx+1, exp_name[chk_idx], exp_rd[chk_idx], exp_val[chk_idx],
                      dut.rd_wb, dut.result_wb);
        end
        chk_idx = chk_idx + 1;
    end
end

//----------------------------------------------------------------
// Waveform dump (view with: gtkwave tb_top_pipeline.vcd)
//----------------------------------------------------------------
initial begin
    $dumpfile("tb_top_pipeline.vcd");
    $dumpvars(0, tb_top_pipeline);
end

//----------------------------------------------------------------
// Main run
//----------------------------------------------------------------
initial begin
    clk = 0;
    rst = 0;
    pass_cnt = 0;
    fail_cnt = 0;

    repeat(3) @(posedge clk);
    rst = 1;

    // Enough cycles for all 57 instructions (39 base + 18 extra) to
    // drain through the 5-stage pipeline with stalls/flushes included.
    repeat(160) @(posedge clk);

    $display("\n================= REGISTER SCOREBOARD =================");
    $display("Checked : %0d / %0d expected writes", pass_cnt+fail_cnt, NUM_EXPECTED);
    $display("Passed  : %0d", pass_cnt);
    $display("Failed  : %0d", fail_cnt);
    if (pass_cnt+fail_cnt < NUM_EXPECTED)
        $display("WARNING : %0d expected instruction(s) never retired (pipeline stuck/stall bug?)",
                  NUM_EXPECTED - (pass_cnt+fail_cnt));

    //----------------------------------------------------------------
    // Direct data-memory checks (stores never hit the regfile)
    //----------------------------------------------------------------
    $display("\n================= MEMORY CHECKS =======================");
    check_mem_byte(0,  8'h0F, "sw x3,0(x0)  byte0 (x3=15)");
    check_mem_byte(4,  8'hFF, "sb x6,4(x0)  (x6 low byte = 0xFF)");
    check_mem_byte(8,  8'hFF, "sh x6,8(x0)  byte0 (0xFFFF low byte)");
    check_mem_byte(9,  8'hFF, "sh x6,8(x0)  byte1 (0xFFFF high byte)");
    check_mem_byte(20, 8'hFF, "sw x24,20(x0) byte0 (0xFFFFFFFF)");
    check_mem_byte(23, 8'hFF, "sw x24,20(x0) byte3 (0xFFFFFFFF)");

    $display("\n================= FINAL SUMMARY ========================");
    if (fail_cnt == 0 && (pass_cnt+fail_cnt) == NUM_EXPECTED && mem_fail_cnt == 0)
        $display(">>> ALL CHECKS PASSED (%0d register checks, %0d memory checks) <<<",
                  pass_cnt, mem_pass_cnt);
    else
        $display(">>> FAILURES DETECTED: %0d register fail(s), %0d memory fail(s), %0d missing retirement(s) <<<",
                  fail_cnt, mem_fail_cnt, NUM_EXPECTED-(pass_cnt+fail_cnt));

    $finish;
end

//----------------------------------------------------------------
// Memory check helper
//----------------------------------------------------------------
integer mem_pass_cnt, mem_fail_cnt;
initial begin
    mem_pass_cnt = 0;
    mem_fail_cnt = 0;
end

task check_mem_byte;
    input [31:0] addr;
    input [7:0]  expected;
    input [319:0] name;
    reg [7:0] got;
    begin
        got = dut.u_data_mem.mem[addr];
        if (got === expected) begin
            mem_pass_cnt = mem_pass_cnt + 1;
            $display("[PASS] %-40s mem[%0d] = 0x%02h", name, addr, got);
        end else begin
            mem_fail_cnt = mem_fail_cnt + 1;
            $display("[FAIL] %-40s mem[%0d] expected 0x%02h got 0x%02h", name, addr, expected, got);
        end
    end
endtask

endmodule