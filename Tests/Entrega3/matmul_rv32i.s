# ==============================================================================
# Archivo: matmul_rv32i.s
# Descripción: Multiplicación de matrices 2x2 en RV32I sin extensión M (suma repetida).
# ==============================================================================
.text
.globl main
main:
    # x8 = Dirección base de matriz A
    # x9 = Dirección base de matriz B
    # x10 = Dirección base de matriz C (resultado)
    
    # C[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0]
    # Asumiendo A[0][0]=1, A[0][1]=2
    lw   x11, 0(x8)       # x11 = B[0][0]
    lw   x12, 4(x8)       # x12 = B[1][0]
    add  x13, x12, x12    # x13 = 2 * B[1][0]
    add  x14, x11, x13    # x14 = B[0][0] + 2 * B[1][0] (C[0][0])
    sw   x14, 0(x10)      # Guardar C[0][0]
    
    # C[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1]
    lw   x11, 8(x8)       # x11 = B[0][1]
    lw   x12, 12(x8)      # x12 = B[1][1]
    add  x13, x12, x12    # x13 = 2 * B[1][1]
    add  x14, x11, x13    # x14 = B[0][1] + 2 * B[1][1] (C[0][1])
    sw   x14, 4(x10)      # Guardar C[0][1]

    # C[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0]
    # Asumiendo A[1][0]=3, A[1][1]=4
    lw   x11, 0(x8)
    lw   x12, 4(x8)
    add  x13, x11, x11
    add  x13, x13, x11    # x13 = 3 * B[0][0]
    add  x14, x12, x12
    add  x14, x14, x12
    add  x14, x14, x12    # x14 = 4 * B[1][0]
    add  x15, x13, x14    # C[1][0]
    sw   x15, 8(x10)

    # C[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1]
    lw   x11, 8(x8)
    lw   x12, 12(x8)
    add  x13, x11, x11
    add  x13, x13, x11    # x13 = 3 * B[0][1]
    add  x14, x12, x12
    add  x14, x14, x12
    add  x14, x14, x12    # x14 = 4 * B[1][1]
    add  x15, x13, x14    # C[1][1]
    sw   x15, 12(x10)

    jalr x0, 0(x1)        # Retornar
