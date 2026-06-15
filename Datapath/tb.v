`timescale 1ns/1ps

module tb;
  logic clk, reset;
  logic [31:0] pcF;
  logic        memWriteM;

  riscv_pipeline dut (
    .clk(clk), .reset(reset),
    .pcF(pcF), .memWriteM(memWriteM)
  );

  initial begin
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
      $display("  [IF ] PC=%08h  Instr=%08h", dut.pcF, dut.instrF);
      $display("  [ID ] Instr=%08h  PC+4=%08h  rs1=x%0d rs2=x%0d rd=x%0d",
               dut.instrD, dut.pcPlus4D, dut.rs1D, dut.rs2D, dut.rdD);
      $display("  [EX ] ALUResult=%08h  WriteData=%08h  Zero=%b  PCSrc=%b  rd=x%0d",
               dut.aluResultE, dut.writeDataE, dut.zeroE, dut.pcSrcE, dut.rdE);
      $display("  [MEM] ALUResult=%08h  WriteData=%08h  MemWrite=%b  rd=x%0d",
               dut.aluResultM, dut.writeDataM, dut.memWriteM, dut.rdM);
      $display("  [WB ] Result=%08h  rd=x%0d", dut.resultW, dut.rdW);
      $display("============================================================");
    end
  end

  // Mismo criterio de exito que Single Cycle/testbench.v (requiere hazard unit completo)
  always @(negedge clk) begin
    if (memWriteM) begin
      if (dut.aluResultM === 32'd100 && dut.writeDataM === 32'd25) begin
        $display("*** SIMULACION EXITOSA: mem[100] = 25 ***");
        #20;
        $finish;
      end else if (dut.aluResultM !== 32'd96) begin
        $display("*** SIMULACION FALLIDA ***");
        $stop;
      end
    end
  end

  initial begin
    #5000;
    $display("*** TIMEOUT: revisar waveforms ***");
    $finish;
  end
endmodule
