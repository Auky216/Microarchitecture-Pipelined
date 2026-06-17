#!/bin/bash
# Script para compilar y ejecutar la simulacion completa del procesador Pipelined RISC-V

echo "========================================================="
echo "Compilando los modulos del procesador..."
echo "========================================================="

# Buscar todos los archivos .v ignorando los directorios inutiles o legacy
find . -name "*.v" | grep -v "/Tests/" | grep -v "Informe_LaTeX" > files_to_compile.txt

# Compilar
iverilog -g2012 -f files_to_compile.txt -o sim.vvp

if [ $? -eq 0 ]; then
    echo "========================================================="
    echo "Simulando..."
    echo "========================================================="
    vvp sim.vvp
    
    # Mover la onda generada a la carpeta Waves
    mv waves.vcd Waves/waves.vcd 2>/dev/null
    
    echo "========================================================="
    echo "Simulacion terminada. La onda se guardo en Waves/waves.vcd"
    echo "========================================================="
else
    echo "========================================================="
    echo "Error en la compilacion. Revisa los mensajes arriba."
    echo "========================================================="
fi

# Limpiar archivos temporales
rm -f files_to_compile.txt sim.vvp
