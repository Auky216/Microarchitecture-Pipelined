`timescale 1ns/1ps

`define CHECK32(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %08h exp %08h", msg, actual, expected); end

`define CHECK5(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got x%0d exp x%0d", msg, actual, expected); end

module tb;
  reg        clk, reset, stallD, flushD, regWriteW;
  reg [31:0] instrF, pcPlus4F, instrD, pcPlus4D, rd1D, rd2D, resultW;
  reg [4:0]  rdW, rs1D, rs2D, rdD;
  integer pass, fail;

  localparam [31:0] INSTR_ADDI = 32'h00500113;
  localparam [31:0] INSTR_ADD  = 32'h002081B3;

  decode dut (
    .clk(clk), .reset(reset),
    .stallD(stallD), .flushD(flushD),
    .instrF(instrF), .pcPlus4F(pcPlus4F),
    .regWriteW(regWriteW), .rdW(rdW), .resultW(resultW),
    .instrD(instrD), .pcPlus4D(pcPlus4D),
    .rd1D(rd1D), .rd2D(rd2D),
    .rs1D(rs1D), .rs2D(rs2D), .rdD(rdD)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    pass = 0; fail = 0;
    reset = 1; stallD = 0; flushD = 0;
    regWriteW = 0; rdW = 0; resultW = 0;
    instrF = INSTR_ADDI; pcPlus4F = 32'd4;
    #12; reset = 0;

    $display("=== TEST DECODE ===");

    @(posedge clk); #1;
    `CHECK32(instrD, INSTR_ADDI, "instrD en IF/ID")
    `CHECK32(pcPlus4D, 32'd4, "pcPlus4D en IF/ID")
    `CHECK5(rs1D, 5'd0, "rs1D x0")
    `CHECK5(rdD, 5'd2, "rdD x2")
    `CHECK32(rd1D, 32'd0, "rd1D lee x0")

    stallD = 1; instrF = INSTR_ADD; pcPlus4F = 32'd8;
    @(posedge clk); #1;
    `CHECK32(instrD, INSTR_ADDI, "instrD con stall")
    stallD = 0;

    @(posedge clk); #1;
    `CHECK32(instrD, INSTR_ADD, "instrD add")
    `CHECK5(rs1D, 5'd1, "rs1D x1")
    `CHECK5(rs2D, 5'd2, "rs2D x2")

    regWriteW = 1; rdW = 5'd1; resultW = 32'd10;
    @(posedge clk); #1;
    regWriteW = 1; rdW = 5'd2; resultW = 32'd5;
    @(posedge clk); #1;
    regWriteW = 0;
    instrF = INSTR_ADD; pcPlus4F = 32'd12;
    @(posedge clk); #1;
    `CHECK32(rd1D, 32'd10, "rd1D x1=10")
    `CHECK32(rd2D, 32'd5, "rd2D x2=5")

    flushD = 1; instrF = INSTR_ADDI; pcPlus4F = 32'd20;
    @(posedge clk); #1;
    flushD = 0;
    `CHECK32(instrD, 32'd0, "instrD tras flush")
    `CHECK32(pcPlus4D, 32'd0, "pcPlus4D tras flush")

    $display("=== DECODE: %0d OK, %0d FAIL ===", pass, fail);
    if (fail == 0) $display("*** DECODE: TODAS LAS PRUEBAS PASARON ***");
    #10 $finish;
  end
endmodule
