module alu(input  [31:0] a, b,
           input  [3:0]  alucontrol,
           output reg [31:0] result,
           output zero);
  
  wire [31:0] sum; 
  wire        isSub;

  assign isSub = (alucontrol == 4'b1000);
  assign sum = a + (isSub ? ~b : b) + isSub; 

  always @* case (alucontrol)
      4'b0000: result = sum;         // add
      4'b1000: result = sum;         // subtract
      4'b0001: result = a << b[4:0]; // sll
      4'b0010: result = (a[31] == b[31]) ? (a < b) : (a[31]); // slt (signed)
      4'b0100: result = a ^ b;       // xor
      4'b0101: result = a >> b[4:0]; // srl
      4'b1101: result = $signed(a) >>> b[4:0]; // sra
      4'b0110: result = a | b;       // or
      4'b0111: result = a & b;       // and
      default: result = 32'bx;
  endcase

  assign zero = (result == 32'b0); 
  
endmodule