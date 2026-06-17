module writeback (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Entradas desde la etapa Memory (M)
  input  logic        RegWriteM,
  input  logic [1:0]  ResultSrcM,
  input  logic [31:0] ALUResultM, ReadDataM,
  input  logic [4:0]  RdM,
  input  logic [31:0] PCPlus4M,
  
  // Salidas hacia la etapa Decode (D) y Forwarding
  output logic        RegWriteW,
  output logic [31:0] ResultW,
  output logic [4:0]  RdW
);

  // Cables internos (salidas del registro MEM/WB)
  logic [1:0]  ResultSrcW;
  logic [31:0] ALUResultW, ReadDataW, PCPlus4W;

  // ==========================================================================
  // REGISTRO MEM/WB (Pipeline Register)
  // ==========================================================================
  // Separa la etapa de Memory de Writeback. 
  // No tiene Stall ni Flush en el diseño básico.
  // Pasan 104 bits en total: 3 bits de Control + 101 bits de Datos.
  
  flopr #(104) memwbReg (
    .clk(clk), .reset(reset),
    .d({RegWriteM, ResultSrcM, ALUResultM, ReadDataM, RdM, PCPlus4M}),
    .q({RegWriteW, ResultSrcW, ALUResultW, ReadDataW, RdW, PCPlus4W})
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
