`timescale 1ns/1ps

`define CHECK32(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %08h exp %08h", msg, actual, expected); end

module tb;
  reg [1:0]  resultSrcW;
  reg [31:0] aluResultW, readDataW, pcPlus4W;
  wire [31:0] resultW;
  integer pass, fail;

  writeback dut (
    .resultSrcW(resultSrcW),
    .aluResultW(aluResultW), .readDataW(readDataW), .pcPlus4W(pcPlus4W),
    .resultW(resultW)
  );

  initial begin
    pass = 0; fail = 0;
    aluResultW = 32'd42;
    readDataW  = 32'd100;
    pcPlus4W   = 32'h1000;

    $display("=== TEST WRITEBACK ===");

    resultSrcW = 2'b00;
    #1;
    `CHECK32(resultW, 32'd42, "ResultSrc ALU")

    resultSrcW = 2'b01;
    #1;
    `CHECK32(resultW, 32'd100, "ResultSrc MEM")

    resultSrcW = 2'b10;
    #1;
    `CHECK32(resultW, 32'h1000, "ResultSrc PC+4")

    $display("=== WRITEBACK: %0d OK, %0d FAIL ===", pass, fail);
    if (fail == 0) $display("*** WRITEBACK: TODAS LAS PRUEBAS PASARON ***");
    #10 $finish;
  end
endmodule
