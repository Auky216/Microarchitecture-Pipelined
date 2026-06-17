module execute (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Señales de control de la Hazard Unit (Riesgos)
  input  logic        FlushE,
  input  logic [1:0]  ForwardAE, ForwardBE,
  
  // Entradas desde la etapa Decode (D) - Control
  input  logic        RegWriteD,
  input  logic [1:0]  ResultSrcD,
  input  logic        MemWriteD,
  input  logic        JumpD,
  input  logic        BranchD,
  input  logic [3:0]  ALUControlD, 
  input  logic        ALUSrcD,
  
  // Entradas desde la etapa Decode (D) - Datos
  input  logic [31:0] RD1D, RD2D,
  input  logic [31:0] PCD,
  input  logic [4:0]  Rs1D, Rs2D, RdD,
  input  logic [31:0] ExtImmD,
  input  logic [31:0] PCPlus4D,
  input  logic [31:0] InstrD,
  
  // Entradas desde Memory y Writeback (para Forwarding)
  input  logic [31:0] ALUResultM, ResultW,
  
  // Salidas hacia la etapa Memory (M) y Hazard Unit
  output logic        RegWriteE,
  output logic [1:0]  ResultSrcE,
  output logic        MemWriteE,
  output logic [31:0] ALUResultE, WriteDataE,
  output logic [4:0]  RdE,
  output logic [31:0] PCPlus4E,
  output logic [31:0] InstrE,
  
  // Salidas hacia Fetch y Hazard Unit
  output logic        PCSrcE,
  output logic [31:0] PCTargetE,
  output logic [4:0]  Rs1E, Rs2E
);

  // Cables internos de la etapa Execute (salidas del registro ID/EX)
  logic        JumpE, BranchE, ALUSrcE, ZeroE;
  logic [3:0]  ALUControlE;
  logic [31:0] RD1E, RD2E, PCE, ExtImmE;
  
  // Entradas a la ALU
  logic [31:0] SrcAE, SrcBE;

  // ==========================================================================
  // REGISTRO ID/EX (Pipeline Register)
  // ==========================================================================
  // Este registro separa la etapa de Decode de Execute. 
  // Ojo: En el diagrama no tiene Stall (siempre habilitado, en = 1'b1), pero sí tiene FlushE
  // para vaciarse cuando hay un salto fallido.
  // Tiene un total de 218 bits (Control + Datos).
  
  flopenrc #(218) idexReg (
    .clk(clk), .reset(reset), .en(1'b1), .clear(FlushE),
    .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, 
        RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ExtImmD, PCPlus4D, InstrD}),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE, 
        RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ExtImmE, PCPlus4E, InstrE})
  );

  // ==========================================================================
  // COMPONENTES DE LA ETAPA EXECUTE
  // ==========================================================================

  // Forwarding Mux para la entrada A de la ALU
  // Decide si usar RD1E, o un valor "adelantado" de Writeback o Memory
  mux3 #(32) forwardAmux (
    .d0(RD1E), 
    .d1(ResultW), 
    .d2(ALUResultM),
    .s(ForwardAE), 
    .y(SrcAE)
  );

  // Forwarding Mux para la entrada B de la ALU
  // Decide si usar RD2E, o un valor "adelantado" de Writeback o Memory
  // Nota: La salida de este mux es WriteDataE (el dato que se guardará en memoria)
  mux3 #(32) forwardBmux (
    .d0(RD2E), 
    .d1(ResultW), 
    .d2(ALUResultM),
    .s(ForwardBE), 
    .y(WriteDataE)
  );

  // Mux que selecciona el operando B de la ALU
  // (entre WriteDataE o el Inmediato Extendido)
  mux2 #(32) srcBmux (
    .d0(WriteDataE), 
    .d1(ExtImmE),
    .s(ALUSrcE), 
    .y(SrcBE)
  );

  // ALU (Unidad Aritmético Lógica)
  alu aluUnit (
    .a(SrcAE), 
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE), 
    .zero(ZeroE)
  );

  // Sumador para la dirección de salto (PC + Inmediato Extendido)
  adder pcTargetAdd (
    .a(PCE), 
    .b(ExtImmE), 
    .y(PCTargetE)
  );

  // Lógica para decidir si se toma el salto
  // PCSrcE = 1 si ocurre un Branch válido (BranchE=1 y ZeroE=1) o si es un Jump
  assign PCSrcE = (BranchE & ZeroE) | JumpE;

endmodule
