module decode (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Señales de control de la Hazard Unit (Riesgos)
  input  logic        StallD, FlushD,
  
  // Entradas desde la etapa Fetch (F)
  input  logic [31:0] InstrF, PCF, PCPlus4F,
  
  // Entradas desde la etapa Writeback (W) para el Register File
  input  logic        RegWriteW,
  input  logic [4:0]  RdW,
  input  logic [31:0] ResultW,
  
  // Salidas hacia la etapa Execute (E) - Datos
  output logic [31:0] InstrD, PCD, PCPlus4D,
  output logic [31:0] RD1D, RD2D,
  output logic [31:0] ExtImmD,
  output logic [4:0]  Rs1D, Rs2D, RdD,
  
  // Salidas hacia la etapa Execute (E) - Señales de Control
  output logic        RegWriteD,
  output logic [1:0]  ResultSrcD,
  output logic        MemWriteD,
  output logic        JumpD,
  output logic        BranchD,
  output logic [3:0]  ALUControlD,
  output logic        ALUSrcD
);

  // ==========================================================================
  // REGISTROS IF/ID (Pipeline Registers)
  // ==========================================================================
  
  // Registro para la Instrucción
  flopenrc #(32) ifIdInstr (
    .clk(clk), .reset(reset), .en(~StallD), .clear(FlushD),
    .d(InstrF), .q(InstrD)
  );

  // Registro para el Program Counter (PC)
  flopenrc #(32) ifIdPc (
    .clk(clk), .reset(reset), .en(~StallD), .clear(FlushD),
    .d(PCF), .q(PCD)
  );

  // Registro para PC + 4
  flopenrc #(32) ifIdPcPlus4 (
    .clk(clk), .reset(reset), .en(~StallD), .clear(FlushD),
    .d(PCPlus4F), .q(PCPlus4D)
  );

  // ==========================================================================
  // EXTRACCIÓN DE CAMPOS DE LA INSTRUCCIÓN
  // ==========================================================================
  
  assign Rs1D = InstrD[19:15]; // Source Register 1
  assign Rs2D = InstrD[24:20]; // Source Register 2
  assign RdD  = InstrD[11:7];  // Destination Register

  // ==========================================================================
  // COMPONENTES DE LA ETAPA DECODE
  // ==========================================================================

  // Register File: Banco de Registros
  // Lee de Rs1D y Rs2D de manera asíncrona (combinacional)
  // Escribe en RdW de manera síncrona en el flanco del reloj si RegWriteW = 1
  regfile rf (
    .clk(clk), .we3(RegWriteW),
    .a1(Rs1D), .a2(Rs2D), .a3(RdW),
    .wd3(ResultW), .rd1(RD1D), .rd2(RD2D)
  );

  // ImmSrcD es una señal de control local (solo se usa dentro de Decode)
  logic [2:0] ImmSrcD;

  // Control Unit: Decodifica la instrucción y genera las señales de control
  controller ctrl (
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7(InstrD[31:25]),
    .RegWrite(RegWriteD),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .Jump(JumpD),
    .Branch(BranchD),
    .ALUControl(ALUControlD),
    .ALUSrc(ALUSrcD),
    .ImmSrc(ImmSrcD)
  );

  // Extend Unit: Extiende el inmediato según el tipo de instrucción
  extend ext (
    .instr(InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ExtImmD)
  );

endmodule
