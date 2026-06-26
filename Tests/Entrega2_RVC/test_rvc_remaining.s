# ==============================================================================
# Archivo: test_rvc_remaining.s
# Objetivo: Validar las 14 instrucciones de la extensión RVC que no se habían
#           probado en los tests anteriores (basic, branches, memory).
#
# Instrucciones probadas aquí:
#   1. c.lwsp rd, imm(x2)    - Carga de palabra relativa a Stack Pointer
#   2. c.swsp rs2, imm(x2)   - Escritura de palabra relativa a Stack Pointer
#   3. c.slli rd, shamt      - Desplazamiento lógico a la izquierda (inmediato)
#   4. c.srli rd', shamt     - Desplazamiento lógico a la derecha (inmediato, x8-x15)
#   5. c.srai rd', shamt     - Desplazamiento aritmético a la derecha (inmediato, x8-x15)
#   6. c.andi rd', imm       - AND con inmediato (x8-x15)
#   7. c.add rd, rs2         - Suma registro-registro
#   8. c.xor rd', rs2'       - XOR registro-registro (x8-x15)
#   9. c.or rd', rs2'        - OR registro-registro (x8-x15)
#  10. c.and rd', rs2'       - AND registro-registro (x8-x15)
#  11. c.lui rd, nzimm       - Carga de inmediato superior
#  12. c.jal offset          - Salto incondicional y enlace (x1 = PC+2)
#  13. c.jr rs1              - Salto indirecto a registro sin enlace
#  14. c.jalr rs1            - Salto indirecto a registro con enlace (x1 = PC+2)
# ==============================================================================

.text
.globl _start

_start:
    # 1. Inicialización
    c.addi sp, 16        # sp (x2) = 16 (0x0141)
    c.addi x8, 12        # x8 = 12      (0x0419)
    c.addi x9, 3         # x9 = 3       (0x048D)
    c.addi x10, 10       # x10 = 10     (0x0515)
    c.addi x12, 5        # x12 = 5      (0x0615)
    c.addi x13, 8        # x13 = 8      (0x06A1)

    # 2. Operaciones lógicas e inmediatos
    c.lui x11, 4         # x11 = 4 << 12 = 16384 (0x4000) (0x6591)
    c.slli x8, 2         # x8 = 12 << 2 = 48 (0x30)       (0x040A)
    c.srli x9, 1         # x9 = 3 >> 1 = 1                (0x8085)
    c.srai x8, 3         # x8 = 48 >> 3 = 6               (0x840D)
    c.andi x10, 7        # x10 = 10 & 7 = 2               (0x891D)
    c.andi x9, 3         # x9 = 1 & 3 = 1                 (0x888D)

    # 3. Operaciones de registro a registro
    c.xor x10, x12       # x10 = 2 ^ 5 = 7                (0x8D31)
    c.or x10, x13        # x10 = 7 | 8 = 15 (0xF)         (0x8D55)
    c.and x10, x9        # x10 = 15 & 1 = 1               (0x8D65)
    c.add x11, x12       # x11 = 16384 + 5 = 16389        (0x85B2)

    # 4. Operaciones de Stack Pointer
    c.swsp x11, 4(sp)    # RAM[20] = 16389 (0x4005)       (0xC216)
    c.lwsp x14, 4(sp)    # x14 = RAM[20] = 16389          (0x4712)

    # 5. Saltos
    c.jal target_jal     # ra (x1) = 0x26 (PC+2), salta a target_jal (0x38) (0x2811)
    c.nop                # Retorno de target_jal           (0x0001)
    
    # Cargar dirección absoluta de target_jalr (60 = 0x3C) en x15
    addi x15, x0, 60     # x15 = 60                       (0x03C00793)
    c.jalr x15           # ra (x1) = 0x2E (PC+2), salta a target_jalr (0x3c) (0x9782)
    c.nop                # Retorno de target_jalr          (0x0001)

end_loop:
    c.j end_loop         # Bucle infinito final            (0xA001)
    c.nop                # Relleno                         (0x0001)
    c.nop                # Relleno                         (0x0001)
    c.nop                # Relleno                         (0x0001)

target_jal:
    c.jr ra              # Retorna a 0x26                  (0x8082)
    c.nop                # Relleno                         (0x0001)

target_jalr:
    c.jr ra              # Retorna a 0x2E                  (0x8082)
    c.nop                # Relleno                         (0x0001)
