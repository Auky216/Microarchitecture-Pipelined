module pipelined(
    input  wire clk, reset,
    output wire [31:0] WriteData, DataAdr,
    output wire        MemWrite
);

  // ====================================================================
  // WIRES DE INTERCONEXIÓN ENTRE ETAPAS
  // ====================================================================
  // Fetch
  wire [31:0] InstrF, PCF;
  wire [31:0] InstrD, PCD, PCPlus4D;
  
  // Hazard Unit
  wire StallF, StallD, FlushD, FlushE;
  wire [1:0] ForwardAE, ForwardBE;

  // Decode a Execute
  wire        RegWriteE;
  wire [1:0]  ResultSrcE;
  wire        MemWriteE;
  wire        JumpE;
  wire        BranchE;
  wire [3:0]  ALUControlE;
  wire        ALUSrcE;
  wire [31:0] RD1E, RD2E, PCE;
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire [31:0] ExtImmE, PCPlus4E;

  // Execute a Fetch (Branches)
  wire        PCSrcE;
  wire [31:0] PCTargetE;

  // Execute a Memory
  wire        RegWriteM;
  wire [1:0]  ResultSrcM;
  wire        MemWriteM;
  wire [31:0] ALUResultM, WriteDataM;
  wire [4:0]  RdM;
  wire [31:0] PCPlus4M;

  // ====================================================================
  // ASIGNACIÓN DE SALIDAS PARA EL TESTBENCH
  // ====================================================================
  assign WriteData = WriteDataM;
  assign DataAdr   = ALUResultM;
  assign MemWrite  = MemWriteM;

  // Memory a Writeback
  wire        RegWriteW;
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW;
  wire [4:0]  RdW;
  wire [31:0] PCPlus4W;

  // Writeback a Decode / Execute
  wire [31:0] ResultW;

  // ######################################################################
  // INSTRUCTION MEMORY
  // ######################################################################
  imem inst_mem(
    .a(PCF),
    .rd(InstrF)
  );

  // ######################################################################
  // ETAPA 1: FETCH
  // ######################################################################
  fetch f_stage(
    .clk(clk),
    .reset(reset),
    .PCSrcE(PCSrcE),
    .PCTargetE(PCTargetE),
    .InstrF(InstrF),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .PCF(PCF),
    .InstrD(InstrD),
    .PCD(PCD),
    .PCPlus4D(PCPlus4D)
  );

  // ######################################################################
  // ETAPA 2: DECODE
  // ######################################################################
  decode d_stage(
    .clk(clk),
    .reset(reset),
    .InstrD(InstrD),
    .PCD(PCD),
    .PCPlus4D(PCPlus4D),
    .RegWriteW(RegWriteW),
    .RdW(RdW),
    .ResultW(ResultW),
    .FlushE(FlushE),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .ExtImmE(ExtImmE),
    .PCPlus4E(PCPlus4E)
  );

  // ######################################################################
  // ETAPA 3: EXECUTE
  // ######################################################################
  execute e_stage(
    .clk(clk),
    .reset(reset),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .ExtImmE(ExtImmE),
    .PCPlus4E(PCPlus4E),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .ResultW(ResultW),
    .PCSrcE(PCSrcE),
    .PCTargetE(PCTargetE),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .RdM(RdM),
    .PCPlus4M(PCPlus4M)
  );

  // ######################################################################
  // ETAPA 4: MEMORY
  // ######################################################################
  memory m_stage(
    .clk(clk),
    .reset(reset),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .RdM(RdM),
    .PCPlus4M(PCPlus4M),
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW),
    .ALUResultW(ALUResultW),
    .ReadDataW(ReadDataW),
    .RdW(RdW),
    .PCPlus4W(PCPlus4W)
  );

  // ######################################################################
  // ETAPA 5: WRITEBACK
  // ######################################################################
  writeback w_stage(
    .ALUResultW(ALUResultW),
    .ReadDataW(ReadDataW),
    .PCPlus4W(PCPlus4W),
    .ResultSrcW(ResultSrcW),
    .ResultW(ResultW)
  );

  // ######################################################################
  // HAZARD UNIT
  // ######################################################################
  hunit hazard_unit(
    .Rs1D(InstrD[19:15]),
    .Rs2D(InstrD[24:20]),
    .RdE(RdE),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .PCSrcE(PCSrcE),
    .ResultSrcE(ResultSrcE[0]), // Bit 0 indica Load en este diseño
    .RdM(RdM),
    .RegWriteM(RegWriteM),
    .RdW(RdW),
    .RegWriteW(RegWriteW),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE)
  );

endmodule
