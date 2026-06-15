module memory_stage (
  input  logic        memWriteM,
  input  logic [31:0] aluResultM, writeDataM,
  output logic [31:0] dataAdrM, storeDataM,
  output logic        memWriteOutM
);
  assign dataAdrM     = aluResultM;
  assign storeDataM   = writeDataM;
  assign memWriteOutM = memWriteM;
endmodule
