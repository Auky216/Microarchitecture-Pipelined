module fetch (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Señal de control de la Hazard Unit (Riesgos)
  input  logic        StallF,
  
  // Entradas desde la etapa Execute (E) para los saltos
  input  logic        PCSrcE,
  input  logic [31:0] PCTargetE,
  
  // Salidas de la etapa Fetch (F)
  output logic [31:0] InstrF,
  output logic [31:0] PCF,
  output logic [31:0] PCPlus4F
);

  // Cable interno para el próximo PC (PCF' en el diagrama)
  logic [31:0] PCF_next;

  // ==========================================================================
  // COMPONENTES DE LA ETAPA FETCH
  // ==========================================================================

  // Multiplexor del PC: Selecciona entre PC+4 o la dirección de salto (PCTargetE)
  mux2 #(32) pcmux (
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCF_next)
  );

  // Registro del PC: Guarda el valor actual del PC. 
  // Se detiene si la Hazard Unit activa StallF.
  flopenr #(32) pcReg (
    .clk(clk), .reset(reset), .en(~StallF),
    .d(PCF_next), .q(PCF)
  );

  // Instruction Memory: Memoria de Instrucciones
  // Lee la instrucción en la dirección dada por el PC
  imem imemory (
    .a(PCF),
    .rd(InstrF)
  );

  // Sumador de PC: Calcula PC + 4
  adder pcAdd4 (
    .a(PCF), .b(32'd4), .y(PCPlus4F)
  );

endmodule
