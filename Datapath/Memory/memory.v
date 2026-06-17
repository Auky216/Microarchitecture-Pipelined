module memory_stage (
  // Señales de reloj y reset
  input  logic        clk, reset,
  
  // Entradas desde la etapa Execute (E)
  input  logic        RegWriteE,
  input  logic [1:0]  ResultSrcE,
  input  logic        MemWriteE,
  input  logic [31:0] ALUResultE, WriteDataE,
  input  logic [4:0]  RdE,
  input  logic [31:0] PCPlus4E,
  input  logic [31:0] InstrE,
  
  // Salidas hacia la etapa Writeback (W) y Forwarding
  output logic        RegWriteM,
  output logic [1:0]  ResultSrcM,
  output logic [31:0] ALUResultM,
  output logic [31:0] ReadDataM,
  output logic [4:0]  RdM,
  output logic [31:0] PCPlus4M,
  output logic [31:0] InstrM
);

  // Cables internos
  logic        MemWriteM;
  logic [31:0] WriteDataM;                

  // ==========================================================================
  // REGISTRO EX/MEM (Pipeline Register)
  // ==========================================================================
  // Separa la etapa de Execute de Memory. 
  // En el diagrama base de RISC-V, este registro NO tiene Stall ni Flush.
  // Pasan 137 bits en total: 5 bits de Control + 132 bits de Datos.
  
  flopr #(137) exmemReg (
    .clk(clk), .reset(reset),
    .d({RegWriteE, ResultSrcE, MemWriteE, ALUResultE, WriteDataE, RdE, PCPlus4E, InstrE}),
    .q({RegWriteM, ResultSrcM, MemWriteM, ALUResultM, WriteDataM, RdM, PCPlus4M, InstrM})
  );

  // ==========================================================================
  // COMPONENTES DE LA ETAPA MEMORY
  // ==========================================================================

  // Data Memory: Memoria de Datos
  // Usa ALUResultM como dirección de memoria y WriteDataM como el dato a guardar.
  // Solo escribe si MemWriteM está activo.
  dmem dataMemory (
    .clk(clk), 
    .we(MemWriteM),
    .a(ALUResultM), 
    .wd(WriteDataM),
    .rd(ReadDataM)
  );

endmodule
