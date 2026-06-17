module riscv_pipeline (
  input  logic clk, reset,
  output logic [31:0] PCF,
  output logic        MemWriteM
);
  // Cables para conectar las etapas
  // IF -> ID
  logic [31:0] InstrF, PCPlus4F;
  
  // ID -> EX
  logic [31:0] InstrD, PCD, PCPlus4D, RD1D, RD2D, ExtImmD;
  logic [4:0]  Rs1D, Rs2D, RdD;
  logic        RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
  logic [1:0]  ResultSrcD;
  logic [3:0]  ALUControlD;
  
  // EX -> MEM / Hazard
  logic        RegWriteE, MemWriteE, PCSrcE;
  logic [1:0]  ResultSrcE;
  logic [31:0] ALUResultE, WriteDataE, PCPlus4E, PCTargetE, InstrE;
  logic [4:0]  RdE, Rs1E, Rs2E;
  logic        ZeroE;
  
  // MEM -> WB / Hazard
  logic        RegWriteM_internal;
  logic [1:0]  ResultSrcM;
  logic [31:0] ALUResultM, ReadDataM, PCPlus4M, WriteDataM, InstrM;
  logic [4:0]  RdM;
  
  // WB -> Hazard / Decode
  logic        RegWriteW;
  logic [31:0] ResultW, InstrW;
  logic [4:0]  RdW;
  
  // Hazard Unit
  logic        StallF, StallD, FlushD, FlushE;
  logic [1:0]  ForwardAE, ForwardBE;

  // Instanciación de la etapa Fetch
  fetch fetchStage (
    .clk(clk), .reset(reset),
    .StallF(StallF), .PCSrcE(PCSrcE), .PCTargetE(PCTargetE),
    .InstrF(InstrF), .PCF(PCF), .PCPlus4F(PCPlus4F)
  );

  // Instanciación de la etapa Decode
  decode decodeStage (
    .clk(clk), .reset(reset),
    .StallD(StallD), .FlushD(FlushD),
    .InstrF(InstrF), .PCF(PCF), .PCPlus4F(PCPlus4F),
    .RegWriteW(RegWriteW), .RdW(RdW), .ResultW(ResultW),
    .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D),
    .RD1D(RD1D), .RD2D(RD2D), .ExtImmD(ExtImmD),
    .Rs1D(Rs1D), .Rs2D(Rs2D), .RdD(RdD),
    .RegWriteD(RegWriteD), .ResultSrcD(ResultSrcD), .MemWriteD(MemWriteD),
    .JumpD(JumpD), .BranchD(BranchD), .ALUControlD(ALUControlD), .ALUSrcD(ALUSrcD)
  );

  // Instanciación de la etapa Execute
  execute executeStage (
    .clk(clk), .reset(reset),
    .FlushE(FlushE), .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .RegWriteD(RegWriteD), .ResultSrcD(ResultSrcD), .MemWriteD(MemWriteD),
    .JumpD(JumpD), .BranchD(BranchD), .ALUControlD(ALUControlD), .ALUSrcD(ALUSrcD),
    .RD1D(RD1D), .RD2D(RD2D), .PCD(PCD),
    .Rs1D(Rs1D), .Rs2D(Rs2D), .RdD(RdD),
    .ExtImmD(ExtImmD), .PCPlus4D(PCPlus4D), .InstrD(InstrD),
    .ALUResultM(ALUResultM), .ResultW(ResultW),
    .RegWriteE(RegWriteE), .ResultSrcE(ResultSrcE), .MemWriteE(MemWriteE),
    .ALUResultE(ALUResultE), .WriteDataE(WriteDataE), .RdE(RdE), .PCPlus4E(PCPlus4E), .InstrE(InstrE),
    .PCSrcE(PCSrcE), .PCTargetE(PCTargetE), .Rs1E(Rs1E), .Rs2E(Rs2E)
  );

  // Para conectar ZeroE que está interno a Execute si lo necesitamos en TB
  assign ZeroE = executeStage.ZeroE;

  // Instanciación de la etapa Memory
  memory_stage memStage (
    .clk(clk), .reset(reset),
    .RegWriteE(RegWriteE), .ResultSrcE(ResultSrcE), .MemWriteE(MemWriteE),
    .ALUResultE(ALUResultE), .WriteDataE(WriteDataE), .RdE(RdE), .PCPlus4E(PCPlus4E), .InstrE(InstrE),
    .RegWriteM(RegWriteM_internal), .ResultSrcM(ResultSrcM),
    .ALUResultM(ALUResultM), .ReadDataM(ReadDataM), .RdM(RdM), .PCPlus4M(PCPlus4M), .InstrM(InstrM)
  );
  
  // Extraemos variables internas de Memory para el Hazard Unit y el Testbench
  assign MemWriteM  = memStage.MemWriteM;
  assign WriteDataM = memStage.WriteDataM;

  // Instanciación de la etapa Writeback
  writeback wbStage (
    .clk(clk), .reset(reset),
    .RegWriteM(RegWriteM_internal), .ResultSrcM(ResultSrcM),
    .ALUResultM(ALUResultM), .ReadDataM(ReadDataM), .RdM(RdM), .PCPlus4M(PCPlus4M), .InstrM(InstrM),
    .RegWriteW(RegWriteW), .ResultW(ResultW), .RdW(RdW), .InstrW(InstrW)
  );

  // Instanciación de la Hazard Unit
  hunit hazardUnit (
    .Rs1E(Rs1E), .Rs2E(Rs2E), .RdM(RdM), .RdW(RdW),
    .RegWriteM(RegWriteM_internal), .RegWriteW(RegWriteW),
    .Rs1D(Rs1D), .Rs2D(Rs2D), .RdE(RdE),
    .ResultSrcE0(ResultSrcE[0]), .PCSrcE(PCSrcE),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF), .StallD(StallD),
    .FlushD(FlushD), .FlushE(FlushE)
  );

endmodule
