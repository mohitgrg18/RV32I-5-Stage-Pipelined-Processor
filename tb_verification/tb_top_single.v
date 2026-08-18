//======================================================================
// tb_riscv_top.v
// Self-checking testbench for riscv_top, exercising the extended
// program preloaded in Ins_Mem.v:
//   - ADDI / ADD                         (base ALU)
//   - SW/LW, SB/LB/LBU, SH/LH/LHU        (all load/store width variants)
//   - BEQ, BNE, BLT, BGE, BLTU, BGEU     (all six branch types)
//   - JAL, JALR                         (unconditional jumps)
// Expected values were cross-checked against an independent Python
// RV32I functional simulator, not just derived by hand.
//======================================================================
`timescale 1ns/1ps

module tb_riscv_top;

    reg clk;
    reg rst;   // active-low

    riscv_top dut (
        .clk (clk),
        .rst (rst)
    );

    // ---------------- clock ----------------
    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    integer total_checks;
    integer passed_checks;

    // register-file check
    task check_reg(input [4:0] idx, input [31:0] expected, input [8*32-1:0] name);
        begin
            total_checks = total_checks + 1;
            if (dut.u_rf.reg_arr[idx] === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %0s = %0d (0x%08h)", name, dut.u_rf.reg_arr[idx], dut.u_rf.reg_arr[idx]);
            end else begin
                $display("FAIL: %0s = %0d (0x%08h)  expected %0d (0x%08h)",
                          name, dut.u_rf.reg_arr[idx], dut.u_rf.reg_arr[idx], expected, expected);
            end
        end
    endtask

    // data-memory word check (little-endian, 4 bytes starting at 'addr')
    task check_mem_word(input [9:0] addr, input [31:0] expected, input [8*32-1:0] name);
        reg [31:0] actual;
        begin
            actual = {dut.u_dmem.mem[addr+3], dut.u_dmem.mem[addr+2],
                      dut.u_dmem.mem[addr+1], dut.u_dmem.mem[addr]};
            total_checks = total_checks + 1;
            if (actual === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %0s = %0d (0x%08h)", name, actual, actual);
            end else begin
                $display("FAIL: %0s = %0d (0x%08h)  expected %0d (0x%08h)",
                          name, actual, actual, expected, expected);
            end
        end
    endtask

    // data-memory byte check
    task check_mem_byte(input [9:0] addr, input [7:0] expected, input [8*32-1:0] name);
        begin
            total_checks = total_checks + 1;
            if (dut.u_dmem.mem[addr] === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %0s = %0d (0x%02h)", name, dut.u_dmem.mem[addr], dut.u_dmem.mem[addr]);
            end else begin
                $display("FAIL: %0s = %0d (0x%02h)  expected %0d (0x%02h)",
                          name, dut.u_dmem.mem[addr], dut.u_dmem.mem[addr], expected, expected);
            end
        end
    endtask

    // data-memory halfword check (little-endian, 2 bytes starting at 'addr')
    task check_mem_half(input [9:0] addr, input [15:0] expected, input [8*32-1:0] name);
        reg [15:0] actual;
        begin
            actual = {dut.u_dmem.mem[addr+1], dut.u_dmem.mem[addr]};
            total_checks = total_checks + 1;
            if (actual === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %0s = %0d (0x%04h)", name, actual, actual);
            end else begin
                $display("FAIL: %0s = %0d (0x%04h)  expected %0d (0x%04h)",
                          name, actual, actual, expected, expected);
            end
        end
    endtask

    // ---------------- stimulus ----------------
    initial begin
        $dumpfile("riscv_top_tb.vcd");
        $dumpvars(0, tb_riscv_top);

        total_checks  = 0;
        passed_checks = 0;

        clk = 0;
        rst = 0;               // hold reset asserted (active-low)
        repeat (2) @(posedge clk);
        rst = 1;                // release reset

        // 39 instructions, 1 cycle each in this single-cycle core
        // (branches/jumps don't cost extra cycles here). Add margin.
        repeat (45) @(posedge clk);
        #1; // settle after the last edge

        $display("--------------------------------------------------");
        $display(" Base ALU / load-store");
        $display("--------------------------------------------------");
        check_reg(1, 32'd5,           "x1  (addi 5)");
        check_reg(2, 32'd10,          "x2  (addi 10)");
        check_reg(3, 32'd15,          "x3  (x1+x2)");
        check_reg(4, 32'd20,          "x4  (addi 20)");
        check_reg(5, 32'd15,          "x5  (lw mem[0])");
        check_mem_word(10'd0,  32'd15,  "mem[0]  (sw x3)");

        $display("--------------------------------------------------");
        $display(" Byte / halfword load-store variants");
        $display("--------------------------------------------------");
        check_reg(6,  32'hFFFFFFFF,   "x6  (addi -1)");
        check_reg(7,  32'hFFFFFFFF,   "x7  (lb  sign-ext)");
        check_reg(8,  32'd255,        "x8  (lbu zero-ext)");
        check_reg(9,  32'hFFFFFFFF,   "x9  (lh  sign-ext)");
        check_reg(10, 32'd65535,      "x10 (lhu zero-ext)");
        check_mem_byte(10'd4,  8'd255,   "mem[4]  (sb x6, byte)");
        check_mem_half(10'd8,  16'd65535, "mem[8]  (sh x6, halfword)");

        $display("--------------------------------------------------");
        $display(" Branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)");
        $display("--------------------------------------------------");
        check_reg(11, 32'd111, "x11 (beq  taken)");
        check_reg(12, 32'd222, "x12 (bne  taken)");
        check_reg(13, 32'd333, "x13 (blt  not taken)");
        check_reg(14, 32'd444, "x14 (blt  taken)");
        check_reg(15, 32'd555, "x15 (bge  taken)");
        check_reg(16, 32'd666, "x16 (bltu taken)");
        check_reg(17, 32'd777, "x17 (bgeu taken)");

        $display("--------------------------------------------------");
        $display(" Jumps (JAL, JALR)");
        $display("--------------------------------------------------");
        check_reg(18, 32'd136, "x18 (jal  link addr)");
        check_reg(19, 32'd888, "x19 (post-jal)");
        check_reg(20, 32'd148, "x20 (jalr link addr)");
        check_reg(21, 32'd222, "x21 (post-jalr)");

        $display("--------------------------------------------------");
        $display(" PC after program = 0x%08h", dut.PC);
        $display(" Result: %0d / %0d checks passed", passed_checks, total_checks);
        if (passed_checks == total_checks)
            $display(" >>> ALL CHECKS PASSED <<<");
        else
            $display(" >>> %0d CHECK(S) FAILED <<<", total_checks - passed_checks);
        $display("--------------------------------------------------");

        $finish;
    end

    // safety timeout
    initial begin
        #3000;
        $display("ERROR: testbench timed out");
        $finish;
    end

endmodule