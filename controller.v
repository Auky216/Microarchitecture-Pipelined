// --------------------------------------------------------------------
// UNIDAD DE CONTROL (CONTROLLER)
// --------------------------------------------------------------------
module controller(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       Branch, 
    output logic       ALUSrc,
    output logic       RegWrite,
    output logic       Jump,
    output logic [1:0] ImmSrc,
    output logic [3:0] ALUControl
);
    logic [1:0] ALUOp;

    always_comb begin
        RegWrite  = 0; 
        MemWrite  = 0; 
        ALUSrc    = 0;
        ResultSrc = 2'b00; 
        Branch    = 0; 
        Jump      = 0;
        ImmSrc    = 2'b00;
        ALUOp     = 2'b00;

        case(op)
            7'b0000011: begin // LW
                RegWrite=1; ImmSrc=2'b00; ALUSrc=1; ResultSrc=2'b01; ALUOp=2'b00; 
            end
            7'b0100011: begin // SW
                MemWrite=1; ImmSrc=2'b01; ALUSrc=1; ALUOp=2'b00; 
            end
            7'b0110011: begin // R-Type
                RegWrite=1; ImmSrc=2'bxx; ALUSrc=0; ResultSrc=2'b00; ALUOp=2'b10; 
            end
            7'b0010011: begin // I-Type ALU
                RegWrite=1; ImmSrc=2'b00; ALUSrc=1; ResultSrc=2'b00; ALUOp=2'b10; 
            end
            7'b1100011: begin // B-Type (BEQ/BNE)
                Branch=1; ImmSrc=2'b10; ALUSrc=0; ResultSrc=2'b00; ALUOp=2'b01; 
            end
            7'b1101111: begin // JAL
                RegWrite=1; ImmSrc=2'b11; ALUSrc=0; ResultSrc=2'b10; Jump=1; ALUOp=2'bxx; 
            end
            default: ;
        endcase
    end

    logic op5;
    assign op5 = op[5]; 
    logic use_alt_op;
    assign use_alt_op = funct7[5] & (op5 | (funct3 == 3'b101));

    always_comb begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0000; // ADD
            2'b01: ALUControl = 4'b1000; // SUB (Branches)
            2'b10: begin
                case(funct3)
                    3'b000: ALUControl = use_alt_op ? 4'b1000 : 4'b0000; // SUB : ADD
                    3'b001: ALUControl = 4'b0001;                        // SLL / SLLI
                    3'b010: ALUControl = 4'b0010;                        // SLT
                    3'b100: ALUControl = 4'b0100;                        // XOR / XORI
                    3'b101: ALUControl = use_alt_op ? 4'b1101 : 4'b0101; // SRA : SRL
                    3'b110: ALUControl = 4'b0110;                        // OR / ORI
                    3'b111: ALUControl = 4'b0111;                        // AND / ANDI
                    default:ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule