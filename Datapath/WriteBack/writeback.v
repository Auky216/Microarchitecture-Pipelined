module writeback (
  input  logic [1:0]  resultSrcW,
  input  logic [31:0] aluResultW, readDataW, pcPlus4W,
  output logic [31:0] resultW
);
  mux3 #(32) resultMux (
    .d0(aluResultW), .d1(readDataW), .d2(pcPlus4W),
    .s(resultSrcW), .y(resultW)
  );
endmodule
