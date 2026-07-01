# ==============================================================================
# Archivo: test_e3_mem.s
# Descripción: Pruebas de acceso a memoria y stack pointer para la Entrega 3.
# ==============================================================================
.text
.globl main

main:
    addi x8, x0, 0        # x8 = 0
    addi x9, x0, 99       # x9 = 99
    c.sw x9, 0(x8)        # mem[0] = 99
    c.lw x10, 0(x8)       # x10 = 99
    addi x2, x0, 32       # sp = 32
    c.swsp x10, 0(sp)     # mem[32] = 99
    c.lwsp x11, 0(sp)     # x11 = 99
    sw   x11, 200(x0)     # mem[200] = 99 (Meta de éxito)

end_loop:
    c.j  end_loop         # Bucle infinito
