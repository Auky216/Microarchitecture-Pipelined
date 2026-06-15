module writeback(
    // Entradas desde la etapa de Memoria (Registro MEM/WB)
    input  wire [31:0] ALUResultW,
    input  wire [31:0] ReadDataW,
    input  wire [31:0] PCPlus4W,
    input  wire [1:0]  ResultSrcW,

    // Salida hacia la etapa de Decode (Register File) y Execute (Forwarding)
    output wire [31:0] ResultW
);

  // ######################################################################
  // RESULT MULTIPLEXER (mux3)
  // ######################################################################
  // Selecciona qué dato se va a escribir en el banco de registros
  mux3 #(32) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );

endmodule
