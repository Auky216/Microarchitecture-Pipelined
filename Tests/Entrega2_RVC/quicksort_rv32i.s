# ==============================================================================
# Archivo: quicksort_rv32i.s
# Descripción: Implementación de Quicksort en ensamblador RISC-V puro (RV32I)
#              como parte de los benchmarks de comparación de tamaño.
# ==============================================================================

.data
    array: .word 5, 3, 8, 1, 9, 2, 7, 4, 6, 0  # Array a ordenar (10 elementos)
    n:     .word 10

.text
.globl main

main:
    la   a0, array       # a0 = base address del array
    li   a1, 0           # a1 = low = 0
    la   t0, n
    lw   a2, 0(t0)
    addi a2, a2, -1      # a2 = high = n - 1
    
    jal  ra, quicksort   # Llamada a quicksort(array, low, high)
    
end_main:
    j    end_main        # Bucle infinito final

# ==============================================================================
# void quicksort(int arr[], int low, int high)
# ==============================================================================
quicksort:
    bge  a1, a2, qs_end  # Si low >= high, retornar
    
    # Prólogo
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a0, 8(sp)
    sw   a1, 4(sp)
    sw   a2, 0(sp)
    
    # Llama a partition
    jal  ra, partition   # a0 = partition(arr, low, high)
    mv   s0, a0          # s0 = pi (pivot index)
    
    # Restaurar a0, a1, a2 para recursión
    lw   a0, 8(sp)
    lw   a1, 4(sp)
    lw   a2, 0(sp)
    
    # quicksort(arr, low, pi - 1)
    addi a2, s0, -1
    jal  ra, quicksort
    
    # Restaurar a0, a1, a2
    lw   a0, 8(sp)
    lw   a1, 4(sp)
    lw   a2, 0(sp)
    
    # quicksort(arr, pi + 1, high)
    addi a1, s0, 1
    jal  ra, quicksort
    
    # Epílogo
    lw   ra, 12(sp)
    addi sp, sp, 16
qs_end:
    ret

# ==============================================================================
# int partition(int arr[], int low, int high)
# ==============================================================================
partition:
    # a0 = arr, a1 = low, a2 = high
    slli t0, a2, 2
    add  t0, a0, t0
    lw   t1, 0(t0)       # t1 = pivot = arr[high]
    
    addi t2, a1, -1      # t2 = i = low - 1
    mv   t3, a1          # t3 = j = low
    
part_loop:
    bge  t3, a2, part_done # Si j >= high, salir del bucle
    
    slli t4, t3, 2
    add  t4, a0, t4
    lw   t5, 0(t4)       # t5 = arr[j]
    
    bge  t5, t1, part_next # Si arr[j] >= pivot, continuar
    
    addi t2, t2, 1       # i++
    
    # Swap arr[i] and arr[j]
    slli t6, t2, 2
    add  t6, a0, t6
    lw   t0, 0(t6)       # t0 = arr[i]
    sw   t5, 0(t6)       # arr[i] = arr[j]
    sw   t0, 0(t4)       # arr[j] = t0
    
part_next:
    addi t3, t3, 1       # j++
    j    part_loop
    
part_done:
    addi t2, t2, 1       # i++
    
    # Swap arr[i] and arr[high]
    slli t6, t2, 2
    add  t6, a0, t6
    lw   t0, 0(t6)       # t0 = arr[i]
    
    slli t4, a2, 2
    add  t4, a0, t4
    lw   t5, 0(t4)       # t5 = arr[high]
    
    sw   t5, 0(t6)       # arr[i] = arr[high]
    sw   t0, 0(t4)       # arr[high] = arr[i]
    
    mv   a0, t2          # Retornar i
    ret
