# ==============================================================================
# Archivo: test_rvc_basic.s
# Objetivo: Comprobar el incremento del PC (PC+2 vs PC+4) y la correcta 
#           descompresión de instrucciones RVC mezcladas con RV32I.
# ==============================================================================

.text
.align 2
.globl _start

_start:
    # 0x00: Instrucción de 16-bits (Aritmética)
    # Formato: 0x0415
    c.addi x8, 5         # x8 = 5
    
    # 0x02: Instrucción de 16-bits (Aritmética)
    # Formato: 0x04A9
    c.addi x9, 10        # x9 = 10
    
    # 0x04: Instrucción de 32-bits (Alineada correctamente gracias al avance previo de 2+2)
    # Formato: 0x00940533
    add x10, x8, x9      # x10 = 15
    
    # 0x08: Instrucción de 16-bits (ALU R-Type)
    # Formato: 0x8C05
    c.sub x8, x9         # x8 = 5 - 10 = -5
    
    # 0x0A: Instrucción de 16-bits (Salto a dirección PC+4)
    # Formato: 0xA011
    c.j skip             # Salta 4 bytes hacia adelante (evitando el NOP en 0x0C)
    
    # 0x0C: Instrucción de 32-bits (Nunca se ejecuta)
    # Formato: 0x00000013
    nop
    
skip:
    # 0x10: Instrucción de 32-bits (Llegada del salto alineada)
    # Formato: 0x06400593
    addi x11, x0, 100    # x11 = 100
