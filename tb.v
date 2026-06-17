`timescale 1ns/1ps

module tb;
  logic clk, reset;
  logic [31:0] pcF;
  logic        memWriteM;

  riscv_pipeline dut (
    .clk(clk), .reset(reset),
    .PCF(pcF), .MemWriteM(memWriteM)
  );

  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb);
    clk   = 0;
    reset = 1;
    #22;
    reset = 0;
  end

  always #5 clk = ~clk;

  integer cycle;
  initial cycle = 0;

  always @(posedge clk) begin
    if (!reset && cycle <= 30) begin
      cycle <= cycle + 1;
      $display("============================================================");
      $display("CICLO %0d", cycle);
      $display("  [IF ] PC=%08h  Instr=%08h", dut.PCF, dut.InstrF);
      $display("  [ID ] Instr=%08h  PC+4=%08h  rs1=x%0d rs2=x%0d rd=x%0d",
               dut.InstrD, dut.PCPlus4D, dut.Rs1D, dut.Rs2D, dut.RdD);
      $display("  [EX ] ALUResult=%08h  WriteData=%08h  Zero=%b  PCSrc=%b  rd=x%0d",
               dut.ALUResultE, dut.WriteDataE, dut.ZeroE, dut.PCSrcE, dut.RdE);
      $display("  [MEM] ALUResult=%08h  WriteData=%08h  MemWrite=%b  rd=x%0d",
               dut.ALUResultM, dut.WriteDataM, dut.MemWriteM, dut.RdM);
      $display("  [WB ] Result=%08h  rd=x%0d", dut.ResultW, dut.RdW);
      $display("============================================================");
    end
  end

  always @(posedge clk) begin
    if (cycle == 20) begin
      $display("*** SIMULACION MINI-TEST COMPLETADA ***");
      $finish;
    end
  end

  initial begin
    #5000;
    $display("TIMEOUT: revisar waveforms");
    $finish;
  end
endmodule
