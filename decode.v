module decode(
    input  wire clk, reset,

    // Entradas desde la etapa de Fetch (Registro IF/ID)
    input  wire [31:0] InstrD,
    input  wire [31:0] PCD,
    input  wire [31:0] PCPlus4D,

    // Entradas desde la etapa de Writeback (para escritura en el RegFile)
    input  wire        RegWriteW,
    input  wire [4:0]  RdW,
    input  wire [31:0] ResultW,

    // Entrada de Control de Hazard
    input  wire        FlushE,

    // Salidas hacia la etapa de Execute (Registro ID/EX)
    output wire        RegWriteE,
    output wire [1:0]  ResultSrcE,
    output wire        MemWriteE,
    output wire        JumpE,
    output wire        BranchE,
    output wire [3:0]  ALUControlE,
    output wire        ALUSrcE,
    
    output wire [31:0] RD1E,
    output wire [31:0] RD2E,
    output wire [31:0] PCE,
    output wire [4:0]  Rs1E,
    output wire [4:0]  Rs2E,
    output wire [4:0]  RdE,
    output wire [31:0] ExtImmE,
    output wire [31:0] PCPlus4E
);

  // ######################################################################
  // SEÑALES INTERNAS DE LA ETAPA DE DECODE (Sufijo 'D')
  // ######################################################################
  wire       RegWriteD;
  wire [1:0] ResultSrcD;
  wire       MemWriteD;
  wire       JumpD;
  wire       BranchD;
  wire [3:0] ALUControlD;
  wire       ALUSrcD;
  wire [1:0] ImmSrcD;
  
  wire [31:0] RD1_D;
  wire [31:0] RD2_D;
  wire [31:0] ExtImmD;

  // ######################################################################
  // CONTROL UNIT
  // ######################################################################
  controller cu(
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7(InstrD[31:25]),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .Branch(BranchD),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .ImmSrc(ImmSrcD),
    .ALUControl(ALUControlD)
  );

  // ######################################################################
  // REGISTER FILE
  // ######################################################################
  regfile rf(
    .clk(clk), 
    .we3(RegWriteW),       // Viene de Writeback
    .a1(InstrD[19:15]),    // Rs1D
    .a2(InstrD[24:20]),    // Rs2D
    .a3(RdW),              // Registro destino (de Writeback)
    .wd3(ResultW),         // Dato a escribir (de Writeback)
    .rd1(RD1_D), 
    .rd2(RD2_D)
  ); 

  // ######################################################################
  // EXTENSION DE SIGNO
  // ######################################################################
  extend ext(
    .instr(InstrD[31:7]), 
    .immsrc(ImmSrcD), 
    .immext(ExtImmD)
  ); 

  // ######################################################################
  // REGISTRO DE SEGMENTACIÓN ID/EX (El "CLK grande" al final de Decode)
  // ######################################################################
  // Usamos floprc de 186 bits para soportar Flush
  
  floprc #(186) flopr_idex(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, 
        RD1_D, RD2_D, PCD, InstrD[19:15], InstrD[24:20], InstrD[11:7], ExtImmD, PCPlus4D}),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE, 
        RD1E,  RD2E,  PCE, Rs1E,          Rs2E,          RdE,          ExtImmE, PCPlus4E})
  );

endmodule