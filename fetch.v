module fetch(
    input  wire clk, reset,
    input  wire PCSrcE,
    input  wire [31:0] PCTargetE,
    input  wire [31:0] InstrF,       // Viene de la Memoria de Instrucciones
    input  wire        StallF,       // Del Hazard Unit
    input  wire        StallD,       // Del Hazard Unit
    input  wire        FlushD,       // Del Hazard Unit
    output wire [31:0] PCF,          // Va hacia la Memoria de Instrucciones
    
    // Salidas del registro de segmentación IF/ID (El "CLK grande")
    output wire [31:0] InstrD,
    output wire [31:0] PCD,
    output wire [31:0] PCPlus4D
);
  
  localparam WIDTH = 32;

  wire [31:0] PCF_; 
  wire [31:0] PCPlus4F;

  // ######################################################################
  // FETCH LÓGICA COMBINACIONAL Y PC
  // ######################################################################

  // Multiplexor del PC
  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4F), 
    .d1(PCTargetE), 
    .s(PCSrcE), 
    .y(PCF_)
  ); 

  // Registro del PC
  flopenr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .en(~StallF),
    .d(PCF_), 
    .q(PCF)
  ); 

  // Sumador PC + 4
  adder pcadd4(
    .a(PCF), 
    .b(32'd4), // Constante 4
    .y(PCPlus4F)
  ); 

  
  // Usamos el módulo flopenrc para soportar Stall y Flush
  flopenrc #(96) flopr_ifid(
    .clk(clk),
    .reset(reset),
    .en(~StallD),
    .clear(FlushD),
    .d({InstrF, PCF, PCPlus4F}),
    .q({InstrD, PCD, PCPlus4D})
  );

endmodule