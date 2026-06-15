module fetch (
  input  logic        clk, reset,
  input  logic        stallF,
  input  logic [31:0] pcNext,
  output logic [31:0] pcF,
  output logic [31:0] pcPlus4F
);
  flopenr #(32) pcReg (
    .clk(clk), .reset(reset), .en(~stallF),
    .d(pcNext), .q(pcF)
  );

  adder pcAdd4 (
    .a(pcF), .b(32'd4), .y(pcPlus4F)
  );
endmodule
