`timescale 1ns/1ps

module tb_controller;
  logic [6:0] op;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [1:0] ResultSrc;
  logic       MemWrite;
  logic       Branch;
  logic       ALUSrc;
  logic       RegWrite;
  logic       Jump;
  logic [1:0] ImmSrc;
  logic [3:0] ALUControl;

  controller dut (
    .op(op),
    .funct3(funct3),
    .funct7(funct7),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .Branch(Branch),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl)
  );

  initial begin
    $display("=== SIMULACION DEL CONTROLLER ===");
    
    op = 7'b0000011; funct3 = 3'b010; funct7 = 7'b0000000; #10;
    $display("LW   -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0100011; funct3 = 3'b010; funct7 = 7'b0000000; #10;
    $display("SW   -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000; #10;
    $display("ADD  -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000; #10;
    $display("SUB  -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0010011; funct3 = 3'b000; funct7 = 7'b0000000; #10;
    $display("ADDI -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0010011; funct3 = 3'b001; funct7 = 7'b0000000; #10;
    $display("SLLI -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0010011; funct3 = 3'b101; funct7 = 7'b0000000; #10;
    $display("SRLI -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b0010011; funct3 = 3'b101; funct7 = 7'b0100000; #10;
    $display("SRAI -> RegWrite=%b MemWrite=%b ALUSrc=%b ResultSrc=%b ImmSrc=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, ResultSrc, ImmSrc, ALUControl);

    op = 7'b1100011; funct3 = 3'b000; funct7 = 7'b0000000; #10;
    $display("BEQ  -> RegWrite=%b MemWrite=%b ALUSrc=%b Branch=%b Jump=%b ALUControl=%b", RegWrite, MemWrite, ALUSrc, Branch, Jump, ALUControl);

    op = 7'b1101111; funct3 = 3'b000; funct7 = 7'b0000000; #10;
    $display("JAL  -> RegWrite=%b MemWrite=%b ALUSrc=%b Branch=%b Jump=%b ResultSrc=%b", RegWrite, MemWrite, ALUSrc, Branch, Jump, ResultSrc);

    $display("=================================");
    $finish;
  end
endmodule
