module execute (
  input  logic [1:0]  forwardAE, forwardBE,
  input  logic        aluSrcE,
  input  logic [3:0]  aluControlE,
  input  logic        branchE, jumpE, jalrE,
  input  logic [31:0] rd1E, rd2E, immExtE, pcPlus4E,
  input  logic [31:0] aluResultM, resultW,
  output logic [31:0] aluResultE, writeDataE,
  output logic        zeroE, pcSrcE,
  output logic [31:0] pcTargetE
);
  logic [31:0] srcAE, srcBE;

  mux3 #(32) forwardAmux (
    .d0(rd1E), .d1(resultW), .d2(aluResultM),
    .s(forwardAE), .y(srcAE)
  );

  mux3 #(32) forwardBmux (
    .d0(rd2E), .d1(resultW), .d2(aluResultM),
    .s(forwardBE), .y(writeDataE)
  );

  mux2 #(32) srcBmux (
    .d0(writeDataE), .d1(immExtE),
    .s(aluSrcE), .y(srcBE)
  );

  alu aluUnit (
    .a(srcAE), .b(srcBE),
    .alucontrol(aluControlE),
    .result(aluResultE), .zero(zeroE)
  );

  assign pcTargetE = jalrE ? ((srcAE + immExtE) & ~32'd1) : (pcPlus4E + immExtE);
  assign pcSrcE    = (branchE & zeroE) | jumpE;
endmodule
