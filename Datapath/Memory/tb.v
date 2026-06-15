`timescale 1ns/1ps

`define CHECK32(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %08h exp %08h", msg, actual, expected); end

`define CHECK1(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %b exp %b", msg, actual, expected); end

module tb;
  reg        memWriteM;
  reg [31:0] aluResultM, writeDataM;
  wire [31:0] dataAdrM, storeDataM;
  wire        memWriteOutM;
  integer pass, fail;

  memory_stage dut (
    .memWriteM(memWriteM),
    .aluResultM(aluResultM), .writeDataM(writeDataM),
    .dataAdrM(dataAdrM), .storeDataM(storeDataM),
    .memWriteOutM(memWriteOutM)
  );

  initial begin
    pass = 0; fail = 0;
    $display("=== TEST MEMORY ===");

    memWriteM = 0;
    aluResultM = 32'd64;
    writeDataM = 32'hDEADBEEF;
    #1;
    `CHECK32(dataAdrM, 32'd64, "dataAdrM lw")
    `CHECK1(memWriteOutM, 1'b0, "memWriteOutM en lw")

    memWriteM = 1;
    aluResultM = 32'd100;
    writeDataM = 32'd25;
    #1;
    `CHECK32(dataAdrM, 32'd100, "dataAdrM sw")
    `CHECK32(storeDataM, 32'd25, "storeDataM sw")
    `CHECK1(memWriteOutM, 1'b1, "memWriteOutM en sw")

    $display("=== MEMORY: %0d OK, %0d FAIL ===", pass, fail);
    if (fail == 0) $display("*** MEMORY: TODAS LAS PRUEBAS PASARON ***");
    #10 $finish;
  end
endmodule
