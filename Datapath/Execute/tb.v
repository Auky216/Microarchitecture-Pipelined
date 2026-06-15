`timescale 1ns/1ps

`define CHECK32(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %08h exp %08h", msg, actual, expected); end

`define CHECK1(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %b exp %b", msg, actual, expected); end

module tb;
  reg [1:0]  forwardAE, forwardBE;
  reg        aluSrcE, branchE, jumpE, jalrE;
  reg [3:0]  aluControlE;
  reg [31:0] rd1E, rd2E, immExtE, pcPlus4E;
  reg [31:0] aluResultM, resultW;
  wire [31:0] aluResultE, writeDataE, pcTargetE;
  wire        zeroE, pcSrcE;
  integer pass, fail;

  execute dut (
    .forwardAE(forwardAE), .forwardBE(forwardBE),
    .aluSrcE(aluSrcE), .aluControlE(aluControlE),
    .branchE(branchE), .jumpE(jumpE), .jalrE(jalrE),
    .rd1E(rd1E), .rd2E(rd2E), .immExtE(immExtE), .pcPlus4E(pcPlus4E),
    .aluResultM(aluResultM), .resultW(resultW),
    .aluResultE(aluResultE), .writeDataE(writeDataE),
    .zeroE(zeroE), .pcSrcE(pcSrcE), .pcTargetE(pcTargetE)
  );

  initial begin
    pass = 0; fail = 0;
    forwardAE = 2'b00; forwardBE = 2'b00;
    branchE = 0; jumpE = 0; jalrE = 0;
    aluResultM = 0; resultW = 0;

    $display("=== TEST EXECUTE ===");

    rd1E = 32'd10; rd2E = 32'd5;
    aluSrcE = 0; aluControlE = 4'b0000;
    #1;
    `CHECK32(aluResultE, 32'd15, "ADD 10+5")
    `CHECK32(writeDataE, 32'd5, "writeDataE sin forward")

    immExtE = 32'd3; aluSrcE = 1;
    #1;
    `CHECK32(aluResultE, 32'd13, "ADDI 10+3")

    forwardAE = 2'b01; resultW = 32'd99; rd1E = 32'd0;
    aluSrcE = 0; aluControlE = 4'b0000; rd2E = 32'd1;
    #1;
    `CHECK32(aluResultE, 32'd100, "ForwardAE desde WB")

    forwardAE = 2'b10; aluResultM = 32'd50; resultW = 0;
    rd2E = 32'd7; forwardBE = 2'b00; aluControlE = 4'b0000;
    #1;
    `CHECK32(aluResultE, 32'd57, "ForwardAE desde MEM")

    forwardAE = 2'b00; forwardBE = 2'b00;
    rd1E = 32'd4; rd2E = 32'd4;
    aluSrcE = 0; aluControlE = 4'b1000;
    branchE = 1; jumpE = 0;
    #1;
    `CHECK1(zeroE, 1'b1, "zeroE en BEQ")
    `CHECK1(pcSrcE, 1'b1, "pcSrcE branch")

    rd2E = 32'd5;
    #1;
    `CHECK1(zeroE, 1'b0, "zeroE BEQ no tomado")
    `CHECK1(pcSrcE, 1'b0, "pcSrcE sin branch")

    branchE = 0; jumpE = 1;
    pcPlus4E = 32'd100; immExtE = 32'd16;
    jalrE = 0;
    #1;
    `CHECK1(pcSrcE, 1'b1, "pcSrcE en JAL")
    `CHECK32(pcTargetE, 32'd116, "PCTarget JAL")

    jumpE = 0; jalrE = 1;
    rd1E = 32'd1000; immExtE = 32'd5;
    #1;
    `CHECK32(pcTargetE, 32'd1004, "PCTarget JALR (LSB en 0)")

    $display("=== EXECUTE: %0d OK, %0d FAIL ===", pass, fail);
    if (fail == 0) $display("*** EXECUTE: TODAS LAS PRUEBAS PASARON ***");
    #10 $finish;
  end
endmodule
