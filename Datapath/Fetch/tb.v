`timescale 1ns/1ps

`define CHECK32(actual, expected, msg) \
  if ((actual) === (expected)) begin pass = pass + 1; $display("  [OK] %s", msg); end \
  else begin fail = fail + 1; $display("  [FAIL] %s: got %08h exp %08h", msg, actual, expected); end

module tb;
  reg        clk, reset, stallF;
  reg [31:0] pcNext, pcF, pcPlus4F;
  integer pass, fail;

  fetch dut (
    .clk(clk), .reset(reset), .stallF(stallF),
    .pcNext(pcNext), .pcF(pcF), .pcPlus4F(pcPlus4F)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    pass = 0; fail = 0;
    reset = 1; stallF = 0; pcNext = 32'd4;

    $display("=== TEST FETCH ===");

    @(posedge clk);
    @(posedge clk);
    #1;
    `CHECK32(pcF, 32'd0, "PC en reset")
    `CHECK32(pcPlus4F, 32'd4, "PC+4 en reset")

    reset = 0;
    @(posedge clk); #1;
    `CHECK32(pcF, 32'd4, "PC actualizado")
    `CHECK32(pcPlus4F, 32'd8, "PC+4")

    stallF = 1; pcNext = 32'd12;
    @(posedge clk); #1;
    `CHECK32(pcF, 32'd4, "PC con stallF")
    `CHECK32(pcPlus4F, 32'd8, "PC+4 con stallF")

    stallF = 0;
    @(posedge clk); #1;
    `CHECK32(pcF, 32'd12, "PC sin stall")
    `CHECK32(pcPlus4F, 32'd16, "PC+4 sin stall")

    $display("=== FETCH: %0d OK, %0d FAIL ===", pass, fail);
    if (fail == 0) $display("*** FETCH: TODAS LAS PRUEBAS PASARON ***");
    #10 $finish;
  end
endmodule
