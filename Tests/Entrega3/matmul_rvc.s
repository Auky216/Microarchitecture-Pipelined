# ==============================================================================
# Archivo: matmul_rvc.s
# Descripción: Multiplicación de matrices 2x2 en RVC (comprimido).
# ==============================================================================
.text
.globl main
main:
    # C[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0]
    c.lw  x11, 0(x8)
    c.lw  x12, 4(x8)
    c.add x13, x12, x12
    c.add x14, x11, x13
    c.sw  x14, 0(x10)
    
    # C[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1]
    c.lw  x11, 8(x8)
    c.lw  x12, 12(x8)
    c.add x13, x12, x12
    c.add x14, x11, x13
    c.sw  x14, 4(x10)

    # C[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0]
    c.lw  x11, 0(x8)
    c.lw  x12, 4(x8)
    c.add x13, x11, x11
    c.add x13, x13, x11
    c.add x14, x12, x12
    c.add x14, x14, x12
    c.add x14, x14, x12
    c.add x15, x13, x14
    c.sw  x15, 8(x10)

    # C[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1]
    c.lw  x11, 8(x8)
    c.lw  x12, 12(x8)
    c.add x13, x11, x11
    c.add x13, x13, x11
    c.add x14, x12, x12
    c.add x14, x14, x12
    c.add x14, x14, x12
    c.add x15, x13, x14
    c.sw  x15, 12(x10)

    c.jr  x1
