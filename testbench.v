module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // instantiate device to be tested
  pipelined dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // initialize test
  initial begin
    clk = 0;
    reset = 0;
    # 1;
    reset = 1; 
    # 22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    # 5; clk = ~clk;
  end

  // check results
  always @(negedge clk) begin
    if (~reset) begin
      $display("Time: %0t, PCF: %h, PCSrcE: %b, FlushE: %b, BranchE: %b, ZeroE: %b | WB: RegWriteW=%b RdW=%0d ResultW=%h", 
               $time, dut.PCF, dut.PCSrcE, dut.FlushE, dut.e_stage.BranchE, dut.e_stage.ZeroE, dut.RegWriteW, dut.RdW, dut.ResultW);
    end

    if(MemWrite) begin
      if(DataAdr === 100 & WriteData === 25) begin
        $display("Simulation succeeded");
        $finish;
      end else if (DataAdr !== 96) begin
        $display("Simulation failed: memory write to %0d with %0d", DataAdr, WriteData);
        $finish;
      end
    end
  end

  // Timeout para la simulación
  initial begin
    #2000;
    $display("Simulation timed out");
    $finish;
  end
endmodule
