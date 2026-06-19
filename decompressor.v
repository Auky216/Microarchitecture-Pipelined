module decompressor(
    input  logic [15:0] cinstr,    // Instrucción de 16-bits
    output logic [31:0] outstr,    // Instrucción expandida de 32-bits
    output logic        is_compressed // Bandera indicadora
);
    // Toda instrucción comprimida termina en 00, 01 o 10. (11 es 32-bits)
    assign is_compressed = (cinstr[1:0] != 2'b11);

    // ========================================================================
    // VARIABLES AUXILIARES (Extracción de campos RVC)
    // ========================================================================
    logic [4:0] rd_rs1;
    logic [4:0] rdp_rs1p; 
    logic [4:0] rs2p;     
    logic [4:0] rs2;

    // Variables para inmediatos
    logic [11:0] imm_addi;
    logic [19:0] imm_lui;
    logic [4:0]  shamt;
    
    // Nuevas variables para Memoria y Saltos
    logic [6:0]  imm_lw_sw;
    logic [7:0]  imm_lwsp;
    logic [7:0]  imm_swsp;
    logic [20:0] j_imm;
    logic [12:0] b_imm;

    // ========================================================================
    // ASIGNACIONES CONTINUAS (Desempaquetado de bits)
    // ========================================================================
    assign rd_rs1   = cinstr[11:7];
    assign rs2      = cinstr[6:2];
    assign rdp_rs1p = {2'b01, cinstr[9:7]}; // Sumar 8 para registros RVC (x8-x15)
    assign rs2p     = {2'b01, cinstr[4:2]}; // Sumar 8 para registros RVC (x8-x15)
    
    assign imm_addi = {{6{cinstr[12]}}, cinstr[12], cinstr[6:2]};
    assign imm_lui  = {{15{cinstr[12]}}, cinstr[6:2]};
    assign shamt    = {cinstr[12], cinstr[6:2]};

    // Immediatos de Memoria
    assign imm_lw_sw = {cinstr[5], cinstr[12:10], cinstr[6], 2'b00};
    assign imm_lwsp  = {cinstr[3:2], cinstr[12], cinstr[6:4], 2'b00};
    assign imm_swsp  = {cinstr[8:7], cinstr[12:9], 2'b00};

    // Immediatos de Saltos (J-Type y B-Type)
    assign j_imm = {{10{cinstr[12]}}, cinstr[8], cinstr[10:9], cinstr[6], cinstr[7], cinstr[2], cinstr[11], cinstr[5:3], 1'b0};
    assign b_imm = {{5{cinstr[12]}}, cinstr[6:5], cinstr[2], cinstr[11:10], cinstr[4:3], 1'b0};

    // ========================================================================
    // LÓGICA DE TRADUCCIÓN A 32-BITS
    // ========================================================================
    always_comb begin
        outstr = 32'h00000013; // Por defecto: NOP (addi x0, x0, 0)
        
        if (is_compressed) begin
            case (cinstr[1:0])
                // -----------------------------------------------------------
                // CUADRANTE 0 (Memoria basada en registros limitados)
                // -----------------------------------------------------------
                2'b00: begin 
                    case (cinstr[15:13])
                        3'b010: outstr = {5'b0, imm_lw_sw, rdp_rs1p, 3'b010, rs2p, 7'b0000011}; // c.lw
                        3'b110: outstr = {5'b0, imm_lw_sw[6:5], rs2p, rdp_rs1p, 3'b010, imm_lw_sw[4:0], 7'b0100011}; // c.sw
                    endcase
                end

                // -----------------------------------------------------------
                // CUADRANTE 1 (Aritmética, Saltos y Branches)
                // -----------------------------------------------------------
                2'b01: begin 
                    case (cinstr[15:13])
                        3'b000: outstr = {imm_addi, rd_rs1, 3'b000, rd_rs1, 7'b0010011}; // c.addi
                        3'b001: outstr = {j_imm[20], j_imm[10:1], j_imm[11], j_imm[19:12], 5'b00001, 7'b1101111}; // c.jal
                        3'b011: outstr = {imm_lui, rd_rs1, 7'b0110111};                  // c.lui
                        3'b100: begin // Grupo ALU
                            case (cinstr[11:10])
                                2'b00: outstr = {7'b0000000, shamt, rdp_rs1p, 3'b101, rdp_rs1p, 7'b0010011}; // c.srli
                                2'b01: outstr = {7'b0100000, shamt, rdp_rs1p, 3'b101, rdp_rs1p, 7'b0010011}; // c.srai
                                2'b10: outstr = {imm_addi, rdp_rs1p, 3'b111, rdp_rs1p, 7'b0010011};          // c.andi
                                2'b11: begin // Operaciones entre registros
                                    case (cinstr[6:5])
                                        2'b00: outstr = {7'b0100000, rs2p, rdp_rs1p, 3'b000, rdp_rs1p, 7'b0110011}; // c.sub
                                        2'b01: outstr = {7'b0000000, rs2p, rdp_rs1p, 3'b100, rdp_rs1p, 7'b0110011}; // c.xor
                                        2'b10: outstr = {7'b0000000, rs2p, rdp_rs1p, 3'b110, rdp_rs1p, 7'b0110011}; // c.or
                                        2'b11: outstr = {7'b0000000, rs2p, rdp_rs1p, 3'b111, rdp_rs1p, 7'b0110011}; // c.and
                                    endcase
                                end
                            endcase
                        end
                        3'b101: outstr = {j_imm[20], j_imm[10:1], j_imm[11], j_imm[19:12], 5'b00000, 7'b1101111}; // c.j
                        3'b110: outstr = {b_imm[12], b_imm[10:5], 5'b00000, rdp_rs1p, 3'b000, b_imm[4:1], b_imm[11], 7'b1100011}; // c.beqz
                        3'b111: outstr = {b_imm[12], b_imm[10:5], 5'b00000, rdp_rs1p, 3'b001, b_imm[4:1], b_imm[11], 7'b1100011}; // c.bnez
                    endcase
                end

                // -----------------------------------------------------------
                // CUADRANTE 2 (Memoria Stack Pointer y Registros completos)
                // -----------------------------------------------------------
                2'b10: begin 
                    case (cinstr[15:13])
                        3'b000: outstr = {7'b0000000, shamt, rd_rs1, 3'b001, rd_rs1, 7'b0010011}; // c.slli
                        3'b010: outstr = {4'b0, imm_lwsp, 5'd2, 3'b010, rd_rs1, 7'b0000011};      // c.lwsp
                        3'b100: begin
                            if (cinstr[12] == 0) begin
                                if (cinstr[6:2] == 0) outstr = {12'b0, rd_rs1, 3'b000, 5'b00000, 7'b1100111}; // c.jr
                                else                  outstr = {7'b0000000, rs2, rd_rs1, 3'b000, rd_rs1, 7'b0110011}; // c.add
                            end else begin
                                if (cinstr[6:2] == 0) outstr = {12'b0, rd_rs1, 3'b000, 5'b00001, 7'b1100111}; // c.jalr
                            end
                        end
                        3'b110: outstr = {4'b0, imm_swsp[7:5], rs2, 5'd2, 3'b010, imm_swsp[4:0], 7'b0100011}; // c.swsp
                    endcase
                end
            endcase
        end
    end
endmodule
