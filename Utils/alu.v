module alu (
  input  logic [31:0] a, b,
  input  logic [3:0]  alucontrol,
  output logic [31:0] result,
  output logic        zero
);
  logic [31:0] condinvb, sum;
  logic        v, isAddSub;

  assign condinvb = alucontrol[3] ? ~b : b;
  assign sum      = a + condinvb + alucontrol[3];
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0];

  always_comb begin
    case (alucontrol)
      4'b0000: result = sum;
      4'b0001: result = a << b[4:0];
      4'b0010: result = $signed(a) < $signed(b) ? 32'd1 : 32'd0;
      4'b0011: result = a < b ? 32'd1 : 32'd0;
      4'b0100: result = a ^ b;
      4'b0101: result = a >> b[4:0];
      4'b0110: result = a | b;
      4'b0111: result = a & b;
      4'b1000: result = sum;
      4'b1101: result = $signed(a) >>> b[4:0];
      4'b1111: result = b;
      default: result = 'x;
    endcase
  end

  assign zero = (result == 32'd0);
  assign v    = ~(alucontrol[3] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
endmodule
