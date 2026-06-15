module riscv_pipeline (
  input  logic clk, reset,
  output logic [31:0] pcF,
  output logic        memWriteM
);
  logic [31:0] instrF, instrD, readDataM;
  logic [31:0] aluResultM, writeDataM, resultW;
  logic [31:0] aluResultE, writeDataE, pcPlus4D;
  logic [1:0]  resultSrcD, resultSrcE, forwardAE, forwardBE;
  logic [3:0]  aluControlD;
  logic [1:0]  immSrcD;
  logic        memWriteD, branchD, aluSrcD, regWriteD, jumpD;
  logic        stallF, stallD, flushD, flushE, pcSrcE, zeroE;
  logic [4:0]  rs1D, rs2D, rdD, rdE, rdM, rdW;

  // Sin hazard unit: sin stall ni forwarding
  assign stallF    = 1'b0;
  assign stallD    = 1'b0;
  assign forwardAE = 2'b00;
  assign forwardBE = 2'b00;

  // Flush minimo para branches/jumps (=== evita propagar X)
  assign flushD = (pcSrcE === 1'b1);
  assign flushE = (pcSrcE === 1'b1);

  imem imemInst (
    .a(pcF), .rd(instrF)
  );

  controller ctrl (
    .op(instrD[6:0]),
    .funct3(instrD[14:12]),
    .funct7(instrD[31:25]),
    .ResultSrc(resultSrcD),
    .MemWrite(memWriteD),
    .Branch(branchD),
    .ALUSrc(aluSrcD),
    .RegWrite(regWriteD),
    .Jump(jumpD),
    .ImmSrc(immSrcD),
    .ALUControl(aluControlD)
  );

  datapath dp (
    .clk(clk), .reset(reset),
    .stallF(stallF), .stallD(stallD),
    .flushD(flushD), .flushE(flushE),
    .forwardAE(forwardAE), .forwardBE(forwardBE),
    .resultSrcD(resultSrcD),
    .memWriteD(memWriteD), .branchD(branchD),
    .aluSrcD(aluSrcD), .regWriteD(regWriteD), .jumpD(jumpD),
    .immSrcD(immSrcD), .aluControlD(aluControlD),
    .instrF(instrF), .readDataM(readDataM),
    .pcF(pcF), .aluResultM(aluResultM),
    .writeDataM(writeDataM), .memWriteM(memWriteM),
    .rs1D(rs1D), .rs2D(rs2D), .rdD(rdD),
    .rdE(rdE), .rdM(rdM), .rdW(rdW),
    .resultSrcE(resultSrcE),
    .pcSrcE(pcSrcE),
    .instrD(instrD), .pcPlus4D(pcPlus4D),
    .aluResultE(aluResultE), .writeDataE(writeDataE),
    .resultW(resultW), .zeroE(zeroE)
  );

  dmem dmemInst (
    .clk(clk), .we(memWriteM),
    .a(aluResultM), .wd(writeDataM), .rd(readDataM)
  );
endmodule
