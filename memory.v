module memory(
    input  wire clk, reset,

    // Entradas desde la etapa de Execute (Registro EX/MEM)
    input  wire        RegWriteM,
    input  wire [1:0]  ResultSrcM,
    input  wire        MemWriteM,
    input  wire [31:0] ALUResultM,
    input  wire [31:0] WriteDataM,
    input  wire [4:0]  RdM,
    input  wire [31:0] PCPlus4M,

    // Salidas hacia la etapa de Writeback (Registro MEM/WB)
    output wire        RegWriteW,
    output wire [1:0]  ResultSrcW,
    output wire [31:0] ALUResultW,
    output wire [31:0] ReadDataW,
    output wire [4:0]  RdW,
    output wire [31:0] PCPlus4W
);

  wire [31:0] ReadDataM;

  // ######################################################################
  // DATA MEMORY
  // ######################################################################
  dmem data_memory(
    .clk(clk),
    .we(MemWriteM),
    .a(ALUResultM),
    .wd(WriteDataM),
    .rd(ReadDataM)
  );

  // ######################################################################
  // REGISTRO DE SEGMENTACIÓN MEM/WB (El "CLK grande" al final de Memory)
  // ######################################################################
  // Control: RegWrite (1), ResultSrc (2) = 3 bits
  // Datos: ALUResult (32), ReadData (32), Rd (5), PCPlus4 (32) = 101 bits
  // Total = 104 bits
  
  flopr #(104) flopr_memwb(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM, ResultSrcM, ALUResultM, ReadDataM, RdM, PCPlus4M}),
    .q({RegWriteW, ResultSrcW, ALUResultW, ReadDataW, RdW, PCPlus4W})
  );

endmodule
