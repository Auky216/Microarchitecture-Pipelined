module datapath (
  input  logic        clk, reset,

  // Hazard unit (sin hazard unit: Stall*=0, Flush*=0, Forward*=00)
  input  logic        stallF, stallD, flushD, flushE,
  input  logic [1:0]  forwardAE, forwardBE,

  // Control desde el controller en etapa ID
  input  logic [1:0]  resultSrcD,
  input  logic        memWriteD, branchD, aluSrcD, regWriteD, jumpD,
  input  logic [1:0]  immSrcD,
  input  logic [3:0]  aluControlD,

  // Instruction memory
  input  logic [31:0] instrF,

  // Data memory
  input  logic [31:0] readDataM,
  output logic [31:0] pcF,
  output logic [31:0] aluResultM,
  output logic [31:0] writeDataM,
  output logic        memWriteM,

  // Salidas para hazard unit / debug
  output logic [4:0]  rs1D, rs2D, rdD, rdE, rdM, rdW,
  output logic [1:0]  resultSrcE,
  output logic        pcSrcE,
  output logic [31:0] instrD, pcPlus4D,
  output logic [31:0] aluResultE, writeDataE,
  output logic [31:0] resultW,
  output logic        zeroE
);
  // ======================== FETCH ========================
  logic [31:0] pcPlus4F, pcNext;

  fetch fetchStage (
    .clk(clk), .reset(reset), .stallF(stallF),
    .pcNext(pcNext), .pcF(pcF), .pcPlus4F(pcPlus4F)
  );

  // ======================== IF/ID -> DECODE ========================
  logic [31:0] rd1D, rd2D, immExtD;

  decode decodeStage (
    .clk(clk), .reset(reset),
    .stallD(stallD), .flushD(flushD),
    .instrF(instrF), .pcPlus4F(pcPlus4F),
    .regWriteW(regWriteW), .rdW(rdW), .resultW(resultW),
    .instrD(instrD), .pcPlus4D(pcPlus4D),
    .rd1D(rd1D), .rd2D(rd2D),
    .rs1D(rs1D), .rs2D(rs2D), .rdD(rdD)
  );

  extend ext (
    .instr(instrD[31:7]), .immsrc(immSrcD), .immext(immExtD)
  );

  // ======================== ID/EX ========================
  logic        regWriteE, memWriteE, aluSrcE, branchE, jumpE;
  logic [3:0]  aluControlE;
  logic [31:0] rd1E, rd2E, immExtE, pcPlus4E;
  logic [4:0]  rs1E, rs2E;
  logic [6:0]  opcodeE;
  logic        jalrE;

  flopenrc #(1) idExRegWrite (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(regWriteD), .q(regWriteE)
  );
  flopenrc #(1) idExMemWrite (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(memWriteD), .q(memWriteE)
  );
  flopenrc #(2) idExResultSrc (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(resultSrcD), .q(resultSrcE)
  );
  flopenrc #(1) idExAluSrc (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(aluSrcD), .q(aluSrcE)
  );
  flopenrc #(1) idExBranch (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(branchD), .q(branchE)
  );
  flopenrc #(1) idExJump (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(jumpD), .q(jumpE)
  );
  flopenrc #(4) idExAluControl (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(aluControlD), .q(aluControlE)
  );
  flopenrc #(32) idExRd1 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(rd1D), .q(rd1E)
  );
  flopenrc #(32) idExRd2 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(rd2D), .q(rd2E)
  );
  flopenrc #(32) idExImmExt (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(immExtD), .q(immExtE)
  );
  flopenrc #(32) idExPcPlus4 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(pcPlus4D), .q(pcPlus4E)
  );
  flopenrc #(5) idExRs1 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(rs1D), .q(rs1E)
  );
  flopenrc #(5) idExRs2 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(rs2D), .q(rs2E)
  );
  flopenrc #(5) idExRd (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(rdD), .q(rdE)
  );
  flopenrc #(7) idExOpcode (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushE),
    .d(instrD[6:0]), .q(opcodeE)
  );

  assign jalrE = (opcodeE == 7'b1100111);

  // ======================== EXECUTE ========================
  logic [31:0] pcTargetE;

  execute executeStage (
    .forwardAE(forwardAE), .forwardBE(forwardBE),
    .aluSrcE(aluSrcE), .aluControlE(aluControlE),
    .branchE(branchE), .jumpE(jumpE), .jalrE(jalrE),
    .rd1E(rd1E), .rd2E(rd2E), .immExtE(immExtE), .pcPlus4E(pcPlus4E),
    .aluResultM(aluResultM), .resultW(resultW),
    .aluResultE(aluResultE), .writeDataE(writeDataE),
    .zeroE(zeroE), .pcSrcE(pcSrcE), .pcTargetE(pcTargetE)
  );

  // ======================== EX/MEM ========================
  logic        regWriteM, regWriteW;
  logic [1:0]  resultSrcM, resultSrcW;
  logic [31:0] pcPlus4M, readDataW, aluResultW, pcPlus4W;

  flopr #(1) exMemRegWrite (
    .clk(clk), .reset(reset),
    .d(regWriteE), .q(regWriteM)
  );
  flopr #(1) exMemMemWrite (
    .clk(clk), .reset(reset),
    .d(memWriteE), .q(memWriteM)
  );
  flopr #(2) exMemResultSrc (
    .clk(clk), .reset(reset),
    .d(resultSrcE), .q(resultSrcM)
  );
  flopr #(32) exMemAluResult (
    .clk(clk), .reset(reset),
    .d(aluResultE), .q(aluResultM)
  );
  flopr #(32) exMemWriteData (
    .clk(clk), .reset(reset),
    .d(writeDataE), .q(writeDataM)
  );
  flopr #(32) exMemPcPlus4 (
    .clk(clk), .reset(reset),
    .d(pcPlus4E), .q(pcPlus4M)
  );
  flopr #(5) exMemRd (
    .clk(clk), .reset(reset),
    .d(rdE), .q(rdM)
  );

  // ======================== MEMORY ========================
  logic        memWriteOutM;
  logic [31:0] dataAdrM, storeDataM;

  memory_stage memStage (
    .memWriteM(memWriteM), .aluResultM(aluResultM), .writeDataM(writeDataM),
    .dataAdrM(dataAdrM), .storeDataM(storeDataM), .memWriteOutM(memWriteOutM)
  );

  // ======================== MEM/WB ========================
  flopr #(1) memWbRegWrite (
    .clk(clk), .reset(reset),
    .d(regWriteM), .q(regWriteW)
  );
  flopr #(2) memWbResultSrc (
    .clk(clk), .reset(reset),
    .d(resultSrcM), .q(resultSrcW)
  );
  flopr #(32) memWbAluResult (
    .clk(clk), .reset(reset),
    .d(aluResultM), .q(aluResultW)
  );
  flopr #(32) memWbReadData (
    .clk(clk), .reset(reset),
    .d(readDataM), .q(readDataW)
  );
  flopr #(32) memWbPcPlus4 (
    .clk(clk), .reset(reset),
    .d(pcPlus4M), .q(pcPlus4W)
  );
  flopr #(5) memWbRd (
    .clk(clk), .reset(reset),
    .d(rdM), .q(rdW)
  );

  // ======================== WRITEBACK ========================
  writeback wbStage (
    .resultSrcW(resultSrcW),
    .aluResultW(aluResultW), .readDataW(readDataW), .pcPlus4W(pcPlus4W),
    .resultW(resultW)
  );

  // ======================== PC NEXT ========================
  mux2 #(32) pcMux (
    .d0(pcPlus4F), .d1(pcTargetE),
    .s(pcSrcE), .y(pcNext)
  );
endmodule
