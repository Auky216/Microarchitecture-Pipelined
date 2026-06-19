module fetch (
  input  logic        clk, reset,
  input  logic        StallF,
  input  logic        PCSrcE,
  input  logic [31:0] PCTargetE,
  output logic [31:0] InstrF,
  output logic [31:0] PCF,
  output logic [31:0] PCPlus4F // Se mantiene este nombre de puerto para no romper el pipeline
);

  logic [31:0] PCF_next;
  logic [31:0] raw_imem_data;
  logic [31:0] actual_instr;
  logic [15:0] cinstr;
  logic [31:0] decompressed_instr;
  logic        is_compressed;
  logic [31:0] pc_increment;

  // Multiplexor del PC
  mux2 #(32) pcmux (
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCF_next)
  );

  // Registro del PC
  flopenr #(32) pcReg (
    .clk(clk), .reset(reset), .en(~StallF),
    .d(PCF_next), .q(PCF)
  );

  // Memoria de Instrucciones
  imem imem_inst (
    .a(PCF),
    .rd(raw_imem_data)
  );

  // Lógica de Alineación (Extracción de la instrucción correcta)
  // Si PC[1] == 1, la instrucción empieza a la mitad de la palabra leída.
  assign actual_instr = PCF[1] ? {16'b0, raw_imem_data[31:16]} : raw_imem_data;

  // Extraemos solo los 16 bits menos significativos para el descompresor
  assign cinstr = actual_instr[15:0];

  // Instanciación del Descompresor
  decompressor decomp (
    .cinstr(cinstr),
    .outstr(decompressed_instr),
    .is_compressed(is_compressed)
  );

  // Mux Final: Seleccionamos la expandida (si era C) o pasamos la normal de 32-bits
  assign InstrF = is_compressed ? decompressed_instr : actual_instr;

  // Incremento Dinámico del PC
  assign pc_increment = is_compressed ? 32'd2 : 32'd4;

  adder pcadd (
    .a(PCF),
    .b(pc_increment),
    .y(PCPlus4F) // Ahora contiene PC + 2 o PC + 4 según corresponda
  );

endmodule
