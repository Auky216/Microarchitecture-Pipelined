# Procesador Segmentado (Pipelined) RISC-V de 5 Etapas en SystemVerilog

Este repositorio contiene el diseño, implementación y simulación de un procesador segmentado de 5 etapas compatible con un conjunto extendido de instrucciones de la arquitectura **RISC-V RV32I**. El diseño incluye una **Hazard Unit** completa capaz de resolver riesgos de datos y riesgos de control en tiempo real mediante técnicas de reenvío (*forwarding*), detención (*stalling*) y vaciado (*flushing*).

---

## 🛠️ Características del Procesador

### 1. Arquitectura de 5 Etapas
El datapath y el control están segmentados síncronamente en las siguientes etapas mediante registros de pipeline (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`):
1. **Fetch (IF)**: Recupera la instrucción desde la memoria de instrucciones (`imem.v`) según el `PC` actual.
2. **Decode (ID)**: Decodifica la instrucción en la Unidad de Control (`controller.v`), lee los operandos desde el Banco de Registros (`regfile.v`) y extiende los inmediatos (`extend.v`).
3. **Execute (EX)**: Realiza la operación aritmético-lógica en la ALU (`alu.v`) y calcula el destino del salto (`PCTargetE`).
4. **Memory (MEM)**: Realiza lecturas y escrituras en la memoria de datos síncrona (`dmem.v`).
5. **Writeback (WB)**: Escribe el resultado final de vuelta en el Banco de Registros en base a la fuente seleccionada (`ResultSrcW`).

### 2. Soporte Extendido de Instrucciones (RV32I)
El procesador soporta un total de 24 instrucciones RV32I:
* **Tipo R**: `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`.
* **Tipo I (ALU)**: `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`.
* **Tipo I (Memoria)**: `lw`.
* **Tipo S**: `sw`.
* **Tipo U**: `lui`.
* **Tipo B**: `beq`, `bne`, `blt`, `bge`.
* **Saltos**: `jal` (tipo J), `jalr` (tipo I).

### 3. Unidad de Riesgos (Hazard Unit)
Implementada modularmente para garantizar la integridad y correctitud en la ejecución del código:
* **Data Forwarding**: Reenvía resultados calculados directamente desde las etapas `Memory` o `Writeback` hacia las entradas de la ALU en la etapa `Execute` para resolver riesgos RAW (Read-After-Write) sin penalizaciones de ciclos.
* **Load-Use Stall**: Detiene las etapas `Fetch` y `Decode` por 1 ciclo de reloj e inserta una burbuja `NOP` en la etapa `Execute` cuando una instrucción de tipo R/I depende inmediatamente de un dato leído por un `lw`.
* **Control Flush**: Limpia y vacía las instrucciones cargadas especulativamente en el pipeline (`FlushD` y `FlushE` en `IF/ID` e `ID/EX`) cuando se toma una bifurcación (`BranchE & TakeBranchE`) o salto incondicional (`JumpE`), redirigiendo el PC al destino real.

---

## 📂 Estructura del Proyecto

```markdown
Microarchitecture-Pipelined/
├── riscv_pipeline.v          # Módulo TOP del procesador (interconecta Datapath y Control)
├── tb.v                      # Testbench de simulación (genera señales de CLK/RST y trazas de consola)
├── run_sim.sh                # Script Bash para compilación y simulación local
├── README.md                 # Documentación del proyecto (Markdown)
├── Controller/
│   └── controller.v          # Unidad de Control principal del procesador (Decodificador de opcodes/funct)
├── Datapath/
│   ├── Fetch/                # Etapa Fetch: fetch.v, imem.v (memoria de instrucciones)
│   ├── Decode/               # Etapa Decode: decode.v, regfile.v (banco de registros de 32 bits)
│   ├── Execute/              # Etapa Execute: execute.v (controla ALU y cálculos de saltos)
│   ├── Memory/               # Etapa Memory: memory.v, dmem.v (memoria de datos síncrona de 64 palabras)
│   └── WriteBack/            # Etapa WriteBack: writeback.v (multiplexión de resultados)
├── Hazard Unit/
│   ├── hunit.v               # Hazard Unit real con detección y resolución de riesgos
│   └── hunit_disabled.v      # Hazard Unit deshabilitada para pruebas de evidenciación de fallos
├── Utils/                    # Componentes genéricos y registros segmentados
│   ├── alu.v                 # Unidad Aritmético-Lógica extendida
│   ├── extend.v              # Extensor de inmediatos de 32 bits (soporta tipos I, S, B, J, U)
│   ├── adder.v               # Sumador aritmético básico
│   ├── mux2.v & mux3.v       # Multiplexores de 2 y 3 canales parametrizables
│   └── flopr.v, flopenr.v, flopenrc.v # Flip-flops segmentados con habilitador y/o limpieza (clear)
├── Tests/                    # Programas ensamblados en hexadecimal (.mem)
│   ├── test_isa_sin_dependencias.mem  # Programa 1: Instrucciones básicas aisladas
│   ├── test_forwarding.mem            # Programa 2: Valida reenvío de datos EX/MEM y MEM/WB
│   ├── test_stalling.mem              # Programa 3: Valida riesgos Load-Use e inserción de stalls
│   ├── test_flushing.mem              # Programa 4: Valida limpieza de pipeline ante saltos condicionales
│   └── test_remaining_ops.mem         # Programa Extra: Validación integral de toda la ISA y Hazard Unit
├── Waves/                    # Archivos de onda VCD generados para GTKWave
│   ├── waves_isa.vcd                  # Traza de ondas de simulación del Programa 1
│   ├── waves_forwarding.vcd           # Traza de ondas de simulación del Programa 2
│   ├── waves_stalling.vcd             # Traza de ondas de simulación del Programa 3
│   ├── waves_flushing.vcd             # Traza de ondas de simulación del Programa 4
│   └── waves_remaining_ops.vcd        # Traza de ondas del Programa Extra completo (24 instrucciones RV32I)
└── Images/                   # Capturas de diagramas del pipeline y waveforms de simulación
```

---

## 🚀 Cómo Ejecutar la Simulación

### Prerrequisitos
Es necesario contar con los siguientes compiladores instalados en la terminal de tu sistema:
* **Icarus Verilog** (`iverilog` para la compilación SystemVerilog).
* **vvp** (motor de simulación de Icarus Verilog).
* **GTKWave** (para la visualización gráfica de trazas `.vcd`).

### Paso 1: Configurar el programa a simular
Por defecto, la memoria de instrucciones (`Datapath/Fetch/imem.v`) carga el programa extra de validación completa. Puedes cambiar el archivo de carga modificando la ruta dentro de `imem.v` en la directiva `$readmemh`:

```verilog
initial begin
    $readmemh("Tests/test_remaining_ops.mem", RAM);
end
```

### Paso 2: Ejecutar el script de simulación
Abre una terminal en la raíz del proyecto y otorga permisos de ejecución al script:

```bash
chmod +x run_sim.sh
./run_sim.sh
```

El script buscará automáticamente todos los archivos fuente `.v` en las subcarpetas, compilará el procesador junto con el testbench y ejecutará la simulación. La salida en consola imprimirá detalladamente la instrucción activa, PC, operandos y resultados de cada una de las 5 etapas ciclo a ciclo.

### Paso 3: Visualizar las formas de onda en GTKWave
Una vez completada la simulación, se genera el archivo de oscilogramas `waves.vcd` dentro de la carpeta `Waves/`. Para abrirlo e inspeccionar las señales:

```bash
gtkwave Waves/waves.vcd
```

Añade las señales deseadas (`clk`, `reset`, `pcF`, `ALUResultE`, `ResultW`, `InstrF`, `InstrD`, `InstrE`, `InstrM`, `InstrW`) al visualizador de GTKWave para observar el correcto solapamiento espacial y temporal de las instrucciones a lo largo del procesador segmentado.
