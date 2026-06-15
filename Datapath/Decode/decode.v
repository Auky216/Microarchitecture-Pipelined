module decode (
  input  logic        clk, reset,
  input  logic        stallD, flushD,
  input  logic [31:0] instrF, pcPlus4F,
  input  logic        regWriteW,
  input  logic [4:0]  rdW,
  input  logic [31:0] resultW,
  output logic [31:0] instrD, pcPlus4D,
  output logic [31:0] rd1D, rd2D,
  output logic [4:0]  rs1D, rs2D, rdD
);
  flopenrc #(32) ifIdInstr (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushD),
    .d(instrF), .q(instrD)
  );

  flopenrc #(32) ifIdPcPlus4 (
    .clk(clk), .reset(reset), .en(~stallD), .clear(flushD),
    .d(pcPlus4F), .q(pcPlus4D)
  );

  assign rs1D = instrD[19:15];
  assign rs2D = instrD[24:20];
  assign rdD  = instrD[11:7];

  regfile rf (
    .clk(clk), .we3(regWriteW),
    .a1(rs1D), .a2(rs2D), .a3(rdW),
    .wd3(resultW), .rd1(rd1D), .rd2(rd2D)
  );
endmodule
