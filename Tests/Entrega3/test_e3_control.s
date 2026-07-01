# ==============================================================================
# Archivo: test_e3_control.s
# Descripción: Pruebas de saltos condicionales e incondicionales para la Entrega 3.
# ==============================================================================
.text
.globl main

main:
    addi x11, x0, 99      # x11 = 99
    c.beqz x11, 4         # Branch no tomado
    c.bnez x11, 6         # Branch tomado -> salta a 0x0C
    addi x12, x0, 77      # Trampa (debe flushearse)

    # Dirección 0x0C
    c.j  4                # Salta a 0x10
    c.nop                 # Trampa (debe flushearse)

    # Dirección 0x10
    addi x13, x0, 42      # x13 = 42
    addi x14, x0, 44      # x14 = 0x2C (Dirección de la subrutina JALR)

    # Dirección 0x18
    c.jal 12              # Salta a subrutina en 0x24. Guarda ra = 0x1A
    c.nop                 # Retorno de c.jal se ejecuta aquí (0x1A)

    # Dirección 0x1C
    c.jalr x14            # Salta a x14 = 0x2C. Guarda ra = 0x1E
    c.nop                 # Retorno de c.jalr se ejecuta aquí (0x1E)

    # Dirección 0x20
    sw   x13, 200(x0)     # mem[200] = 42 (Meta de éxito)

end_loop:
    c.j  end_loop         # Bucle infinito

# ==============================================================================
# SUBRUTINAS
# ==============================================================================
    .align 2
sub_jal:
    # Dirección 0x24
    c.jr x1               # Retorna a ra (0x1A)
    c.nop

sub_jalr:
    # Dirección 0x2C
    c.jr x1               # Retorna a ra (0x1E)
    c.nop
