# ==============================================================================
# Archivo: quicksort_rvc.s
# Descripción: Implementación de Quicksort en ensamblador RISC-V haciendo uso
#              intensivo de la extensión comprimida RVC (Parte 2).
#              Ideal para comparar el tamaño (Code Density) con RV32I.
# ==============================================================================

.data
    array: .word 5, 3, 8, 1, 9, 2, 7, 4, 6, 0
    n:     .word 10

.text
.globl main

main:
    # Sustitución de la e li con c.li donde aplique
    la   a0, array       
    c.li a1, 0           # a1 = low = 0
    la   t0, n
    c.lw a2, 0(t0)       # Ojo: Requiere que t0 esté en x8-x15 y alineado
    c.addi a2, -1        # a2 = high = n - 1
    
    jal  ra, quicksort   
    
end_main:
    c.j  end_main        # Bucle infinito comprimido

# ==============================================================================
# void quicksort(int arr[], int low, int high)
# ==============================================================================
quicksort:
    bge  a1, a2, qs_end  
    
    # Prólogo usando c.addi16sp y c.swsp
    c.addi16sp sp, -16
    c.swsp ra, 12(sp)
    c.swsp a0, 8(sp)
    c.swsp a1, 4(sp)
    c.swsp a2, 0(sp)
    
    jal  ra, partition   
    mv   s0, a0          
    
    # Restaurar
    c.lwsp a0, 8(sp)
    c.lwsp a1, 4(sp)
    c.lwsp a2, 0(sp)
    
    c.addi a2, -1        # Asumiendo a2 hereda de s0 pero requiere ajustarse 
    add  a2, s0, a2      # Equivalente a a2 = s0 - 1
    jal  ra, quicksort
    
    c.lwsp a0, 8(sp)
    c.lwsp a1, 4(sp)
    c.lwsp a2, 0(sp)
    
    c.addi a1, 1         
    add  a1, s0, a1      # Equivalente a a1 = s0 + 1
    jal  ra, quicksort
    
    # Epílogo
    c.lwsp ra, 12(sp)
    c.addi16sp sp, 16
qs_end:
    c.jr ra              # Retorno comprimido

# ==============================================================================
# int partition(int arr[], int low, int high)
# ==============================================================================
partition:
    # A efectos del RVC, se buscan instrucciones como c.slli, c.add, etc.
    mv   t0, a2
    c.slli t0, 2
    c.add  t0, a0        # t0 = a0 + t0
    c.lw   t1, 0(t0)     # t1 = pivot = arr[high]
    
    mv   t2, a1
    c.addi t2, -1        # t2 = i = low - 1
    mv   t3, a1          # t3 = j = low
    
part_loop:
    bge  t3, a2, part_done 
    
    mv   t4, t3
    c.slli t4, 2
    c.add  t4, a0
    c.lw   t5, 0(t4)     # t5 = arr[j]
    
    bge  t5, t1, part_next 
    
    c.addi t2, 1         # i++
    
    # Swap arr[i] and arr[j]
    mv   t6, t2
    c.slli t6, 2
    c.add  t6, a0
    c.lw   t0, 0(t6)     # t0 = arr[i]
    c.sw   t5, 0(t6)     # arr[i] = arr[j]
    c.sw   t0, 0(t4)     # arr[j] = t0
    
part_next:
    c.addi t3, 1         # j++
    c.j    part_loop
    
part_done:
    c.addi t2, 1         # i++
    
    # Swap arr[i] and arr[high]
    mv   t6, t2
    c.slli t6, 2
    c.add  t6, a0
    c.lw   t0, 0(t6)     
    
    mv   t4, a2
    c.slli t4, 2
    c.add  t4, a0
    c.lw   t5, 0(t4)     
    
    c.sw   t5, 0(t6)     
    c.sw   t0, 0(t4)     
    
    mv   a0, t2          # Retornar i
    c.jr ra
