module execute(
    input  wire clk, reset,

    // Entradas desde la etapa de Decode (Registro ID/EX)
    input  wire        RegWriteE,
    input  wire [1:0]  ResultSrcE,
    input  wire        MemWriteE,
    input  wire        JumpE,
    input  wire        BranchE,
    input  wire [3:0]  ALUControlE,
    input  wire        ALUSrcE,
    
    input  wire [31:0] RD1E,
    input  wire [31:0] RD2E,
    input  wire [31:0] PCE,
    input  wire [4:0]  Rs1E,
    input  wire [4:0]  Rs2E,
    input  wire [4:0]  RdE,
    input  wire [31:0] ExtImmE,
    input  wire [31:0] PCPlus4E,

    // Entradas para Forwarding (desde la Hazard Unit y otras etapas)
    input  wire [1:0]  ForwardAE,
    input  wire [1:0]  ForwardBE,
    input  wire [31:0] ResultW,      // Desde la etapa Writeback

    // Salidas hacia la etapa de Fetch
    output wire        PCSrcE,
    output wire [31:0] PCTargetE,

    // Salidas hacia la etapa de Memory (Registro EX/MEM)
    output wire        RegWriteM,
    output wire [1:0]  ResultSrcM,
    output wire        MemWriteM,
    output wire [31:0] ALUResultM,   // También la usaremos internamente para forwarding
    output wire [31:0] WriteDataM,
    output wire [4:0]  RdM,
    output wire [31:0] PCPlus4M
);

  // ######################################################################
  // SEÑALES INTERNAS DE LA ETAPA DE EXECUTE
  // ######################################################################
  wire [31:0] SrcAE;
  wire [31:0] WriteDataE;
  wire [31:0] SrcBE;
  wire [31:0] ALUResultE;
  wire        ZeroE;

  // ######################################################################
  // FORWARDING MULTIPLEXERS (mux3)
  // ######################################################################
  // Mux para SrcAE (Selecciona entre RD1E, ResultW, y ALUResultM)
  mux3 #(32) forwardA_mux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),   // Usamos nuestra propia salida M (que sale del EX/MEM) para forwarding
    .s(ForwardAE),
    .y(SrcAE)
  );

  // Mux para WriteDataE (Selecciona entre RD2E, ResultW, y ALUResultM)
  mux3 #(32) forwardB_mux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(WriteDataE)
  );

  // ######################################################################
  // ALU SRC MULTIPLEXER (mux2)
  // ######################################################################
  // Mux para SrcBE (Selecciona entre WriteDataE y ExtImmE)
  mux2 #(32) srcbmux(
    .d0(WriteDataE),
    .d1(ExtImmE),
    .s(ALUSrcE),
    .y(SrcBE)
  );

  // ######################################################################
  // ALU
  // ######################################################################
  alu alu(
    .a(SrcAE),
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  );

  // ######################################################################
  // BRANCH TARGET ADDER
  // ######################################################################
  adder pcaddbranch(
    .a(PCE),
    .b(ExtImmE),
    .y(PCTargetE)
  );

  // ######################################################################
  // PCSrcE LOGIC
  // ######################################################################
  assign PCSrcE = JumpE | (BranchE & ZeroE);

  // ######################################################################
  // REGISTRO DE SEGMENTACIÓN EX/MEM (El "CLK grande" al final de Execute)
  // ######################################################################
  // Concatenamos las señales de Control y de Datos
  always @(negedge clk) begin
    $display("Execute Time=%0t: SrcAE=%h SrcBE=%h ALUControlE=%b ALUResultE=%h ZeroE=%b ForwardAE=%b ForwardBE=%b RD1E=%h RD2E=%h", $time, SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE, ForwardAE, ForwardBE, RD1E, RD2E);
  end

  // ====================================================================
  // REGISTRO DE SEGMENTACIÓN EX/MEM (El "CLK grande" al final de Execute)
  // ====================================================================
  flopr #(105) flopr_exmem(
    .clk(clk),
    .reset(reset),
    .d({RegWriteE, ResultSrcE, MemWriteE, ALUResultE, WriteDataE, RdE, PCPlus4E}),
    .q({RegWriteM, ResultSrcM, MemWriteM, ALUResultM, WriteDataM, RdM, PCPlus4M})
  );

endmodule
