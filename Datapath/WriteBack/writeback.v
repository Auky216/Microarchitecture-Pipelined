module writeback (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Entradas desde la etapa Memory (M)
  input  logic        RegWriteM,
  input  logic [1:0]  ResultSrcM,
  input  logic [31:0] ALUResultM, ReadDataM,
  input  logic [4:0]  RdM,
  input  logic [31:0] PCPlus4M,
  input  logic [31:0] InstrM,
  
  // Salidas hacia la etapa Decode (D) y Forwarding
  output logic        RegWriteW,
  output logic [31:0] ResultW,
  output logic [4:0]  RdW,
  output logic [31:0] InstrW
);

  // Cables internos (salidas del registro MEM/WB)
  logic [1:0]  ResultSrcW;
  logic [31:0] ALUResultW, ReadDataW, PCPlus4W;

  // ==========================================================================
  // REGISTRO MEM/WB (Pipeline Register)
  // ==========================================================================
  // Separa la etapa de Memory de Writeback. 
  // No tiene Stall ni Flush en el diseño básico.
  // Pasan 136 bits en total: 4 bits de Control + 132 bits de Datos.
  
  flopr #(136) memwbReg (
    .clk(clk), .reset(reset),
    .d({RegWriteM, ResultSrcM, ALUResultM, ReadDataM, RdM, PCPlus4M, InstrM}),
    .q({RegWriteW, ResultSrcW, ALUResultW, ReadDataW, RdW, PCPlus4W, InstrW})
  );

  // ==========================================================================
  // COMPONENTES DE LA ETAPA WRITEBACK
  // ==========================================================================

  // Multiplexor de Resultado
  // Selecciona qué dato se guardará en el Register File (o se reenviará por forwarding)
  // 00 -> Resultado de la ALU
  // 01 -> Dato leído de la Memoria
  // 10 -> PC + 4 (Usado típicamente para llamadas a funciones: JAL/JALR)
  mux3 #(32) resultMux (
    .d0(ALUResultW), 
    .d1(ReadDataW), 
    .d2(PCPlus4W),
    .s(ResultSrcW), 
    .y(ResultW)
  );

endmodule
