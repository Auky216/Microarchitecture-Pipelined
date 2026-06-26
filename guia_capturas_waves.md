# Guía de Validación de Señales y Capturas de Pantalla (GTKWave) para el Informe

Esta guía detalla de forma exhaustiva las instrucciones de hardware del procesador, el análisis paso a paso de los fallos que ocurren al desactivar la **Hazard Unit**, y proporciona instrucciones exactas sobre **qué capturas de pantalla tomar en GTKWave**, qué señales mostrar, y qué elementos subrayar o encerrar con colores para documentar el comportamiento del procesador de forma robusta y profesional.

---

## 1. Resumen de Instrucciones Nuevas e Implementadas (RV32I y RVC) en Código Verilog

Para cumplir con el requerimiento del evaluador de **mostrar código Verilog real en lugar de pseudocódigo**, se detallan a continuación las implementaciones físicas en los archivos fuente del proyecto:

### A. Extensiones de la ALU (`Utils/alu.v`)
Las instrucciones lógicas, aritméticas y comparativas agregadas se ejecutan de manera combinacional en la ALU según la señal `alucontrol[3:0]`:

```verilog
// Desplazamientos lógicos y aritméticos (SLLI, SRLI, SRAI, SLL, SRL, SRA)
4'b0001: result = a << b[4:0];                    // SLL / SLLI (Desplazamiento a la izquierda)
4'b0101: result = a >> b[4:0];                    // SRL / SRLI (Desplazamiento a la derecha lógico)
4'b1101: result = $signed(a) >>> b[4:0];          // SRA / SRAI (Desplazamiento a la derecha aritmético con signo)

// Operaciones lógicas (XOR, XORI, OR, ORI, AND, ANDI)
4'b0100: result = a ^ b;                          // XOR / XORI
4'b0110: result = a | b;                          // OR / ORI
4'b0111: result = a & b;                          // AND / ANDI

// Comparaciones (SLT, SLTI, SLTU)
4'b0010: result = $signed(a) < $signed(b) ? 32'd1 : 32'd0; // SLT / SLTI (Comparación con signo)
4'b0011: result = a < b ? 32'd1 : 32'd0;                   // SLTU / SLTUI (Comparación sin signo)

// Soporte LUI (Load Upper Immediate)
4'b1111: result = b;                              // Modo pasarela: la ALU pasa directamente el operando B (inmediato de 20 bits extendido en U-type)
```

### B. Unidad de Extensión de Inmediatos (`Utils/extend.v`)
El soporte para inmediatos de tipo U (LUI), J (JAL) y B (Branches) se realiza en el decodificador de extensión usando `immsrc[2:0]`:

```verilog
always_comb begin
  case(immsrc) 
    3'b000:   immext = {{20{instr[31]}}, instr[31:20]};                       // I-type (Loads, Arithmetic Imm, JALR)
    3'b001:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};          // S-type (sw)
    3'b010:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type (branches)
    3'b011:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type (jal)
    3'b100:   immext = {instr[31:12], 12'b0};                                 // U-type (lui)
    default:  immext = 32'bx;
  endcase             
end
```

### C. Descompresión de Instrucciones RVC (`decompressor.v`)
La traducción en tiempo cero de instrucciones de 16 bits a equivalentes RV32I de 32 bits se maneja con multiplexores combinacionales:

```verilog
// Ejemplo para memoria (c.lw y c.sw)
2'b00: begin 
    case (cinstr[15:13])
        3'b010: outstr = {5'b0, imm_lw_sw, rdp_rs1p, 3'b010, rs2p, 7'b0000011}; // c.lw -> lw rdp_rs1p, imm(rs2p)
        3'b110: outstr = {5'b0, imm_lw_sw[6:5], rs2p, rdp_rs1p, 3'b010, imm_lw_sw[4:0], 7'b0100011}; // c.sw -> sw rs2p, imm(rdp_rs1p)
    endcase
end

// Ejemplo para branches condicionales (c.beqz y c.bnez)
3'b110: outstr = {b_imm[12], b_imm[10:5], 5'b00000, rdp_rs1p, 3'b000, b_imm[4:1], b_imm[11], 7'b1100011}; // c.beqz -> beq rdp_rs1p, x0, b_imm
3'b111: outstr = {b_imm[12], b_imm[10:5], 5'b00000, rdp_rs1p, 3'b001, b_imm[4:1], b_imm[11], 7'b1100011}; // c.bnez -> bne rdp_rs1p, x0, b_imm
```

---

## 2. Análisis Detallado de Fallos (Sin Hazard Unit)

El evaluador penalizó la explicación de fallos por ser muy simple. A continuación se describe el comportamiento físico exacto de por qué los programas **fallan críticamente** si se desactiva la Hazard Unit (`hunit`):

### ❌ Programa 2 (Forwarding): Falla de Dependencia RAW
* **Código:**
  ```assembly
  0x00: addi x2, x0, 5
  0x04: addi x3, x0, 12
  0x08: add  x4, x2, x3
  ```
* **Mecanismo de Falla:**
  1. `addi x2` calcula el valor `5` en el ciclo 3 (etapa Execute) y avanza.
  2. `addi x3` calcula el valor `12` en el ciclo 4 (etapa Execute).
  3. En el ciclo 4, la instrucción `add x4, x2, x3` está en la etapa **Decode** y lee los registros del banco. Como el banco de registros solo actualiza sus salidas al final de la etapa de Writeback (ciclo 5 para `x2` y ciclo 6 para `x3`), los valores leídos para ambos registros son `0x00000000` (el valor antiguo).
  4. En el ciclo 5, la instrucción `add x4` pasa a la etapa **Execute**. Sin la Hazard Unit, no hay señales de forwarding (`ForwardAE = 00`, `ForwardBE = 00`). La ALU realiza la operación:
     $$\text{Result} = 0 + 0 = 0$$
  5. En lugar de almacenar `17` (`0x11`) en `x4`, se escribe `0` en el banco de registros en el ciclo 7.
  * **Error:** La dependencia de datos tipo *Read After Write* (RAW) se ignora, causando corrupción del cálculo matemático silenciosamente.

### ❌ Programa 3 (Stalling): Falla de Dependencia Load-Use
* **Código:**
  ```assembly
  0x08: lw   x3, 100(x0)
  0x0C: add  x4, x3, x2
  ```
* **Mecanismo de Falla:**
  1. La instrucción `lw x3` calcula la dirección de memoria (`100`) en el ciclo 5 (EX) y accede al puerto de la RAM de datos en el ciclo 6 (MEM).
  2. En el ciclo 6, la instrucción `add x4` se encuentra en la etapa **Execute** y requiere el valor cargado de `x3`.
  3. Como la memoria de datos entrega el valor recién al finalizar el ciclo 6, este valor no se puede reenvíar hacia Execute a tiempo sin congelar el pipeline.
  4. Sin la Hazard Unit, no se activa `StallF` ni `StallD`, por lo que el procesador no inserta ninguna burbuja de espera. `add x4` continúa su ejecución en Execute leyendo el contenido obsoleto del bus o el valor inicial de `x3` en el banco de registros (`0`).
  5. La ALU calcula:
     $$\text{Result} = x3_{old} + x2 = 0 + 5 = 5$$
  6. En el ciclo 7, el dato real leído de la memoria por `lw` (`42` o similar) llega a Writeback, pero ya es tarde: la operación `add` ya calculó el valor incorrecto `5` y lo propagó a las siguientes etapas.
  * **Error:** El pipeline no se detiene para esperar a que los datos leídos de la memoria estén disponibles en el bus de salida de la etapa MEM.

### ❌ Programa 4 (Flushing): Pérdida de Control en Saltos Tomados
* **Código:**
  ```assembly
  0x00: addi x2, x0, 5
  0x04: beq  x2, x2, 12   # Salta a 0x10
  0x08: addi x3, x0, 1    # ¡Instrucción especulativa! (Debe ser borrada)
  0x0C: addi x3, x0, 1    # ¡Instrucción especulativa! (Debe ser borrada)
  0x10: add  x4, x0, x2   # Destino del salto
  ```
* **Mecanismo de Falla:**
  1. En el ciclo 4, `beq` está en la etapa **Execute**. La ALU evalúa la igualdad `x2 == x2` y activa `PCSrcE = 1`. El multiplexor del PC selecciona el destino del salto (`0x10`) para el próximo ciclo.
  2. Al mismo tiempo, en el ciclo 4, las instrucciones de las direcciones `0x08` (en Decode) y `0x0C` (en Fetch) ya ingresaron al procesador debido a la precarga secuencial.
  3. Sin la Hazard Unit, las señales `FlushD` y `FlushE` permanecen en `0`. Los registros de pipeline `IF/ID` e `ID/EX` no se borran.
  4. En los ciclos 5 y 6, las instrucciones en `0x08` y `0x0C` continúan su curso normal por las etapas de Execute, Memory y Writeback, escribiendo el valor `1` en el registro `x3`.
  * **Error:** Se ejecuta código en la ruta especulativa del salto tomado. La memoria y el banco de registros se modifican con valores que el programa nunca debió procesar, rompiendo el flujo lógico del programa.

---

## 3. Plan de Capturas de Pantalla en GTKWave

Para impresionar al evaluador, debes tomar **dos capturas de pantalla por programa**: una con la Hazard Unit **desactivada** (para mostrar el fallo exacto en los cables) y otra con la Hazard Unit **activada** (para mostrar la corrección).

### 📋 Configuración Global de Señales en GTKWave
Para todos los casos, agrega y agrupa las siguientes señales:
* **Generales:** `tb/clk`, `tb/reset`
* **Fetch:** `tb/dut/PCF`, `tb/dut/InstrF`
* **Decode:** `tb/dut/InstrD`, `tb/dut/decodeStage/rf/rf[...]` (Registros de prueba del programa)
* **Execute:** `tb/dut/executeStage/ALUResultE`, `tb/dut/executeStage/ForwardAE`, `tb/dut/executeStage/ForwardBE`
* **Memory:** `tb/dut/memStage/MemWriteM`, `tb/dut/memStage/ALUResultM`, `tb/dut/memStage/WriteDataM`
* **Hazard Unit:** `tb/dut/hazardUnit/StallF`, `tb/dut/hazardUnit/StallD`, `tb/dut/hazardUnit/FlushD`, `tb/dut/hazardUnit/FlushE`

---

### 📸 Captura 1: Programa de Forwarding (`test_forwarding.mem`)

* **Caso de Fallo (Hazard Unit Desactivada):**
  * **Dónde hacer Zoom:** Ciclos 4 a 6.
  * **Qué resaltar en la Waveform (Dibujar recuadro ROJO):** 
    * Señala `ForwardAE` y `ForwardBE` en valor `2'b00` (desactivados).
    * Subraya las entradas de la ALU `SrcAE` y `SrcBE` en `0`.
    * Enmarca `ALUResultE` en el ciclo 5 mostrando el valor incorrecto `0` (en lugar de `17`).
  * **Explicación del Fallo:** Sin forwarding, los datos calculados de las instrucciones previas se quedan atascados en las etapas MEM y WB y no regresan a la ALU. La suma se calcula con registros vacíos.

* **Caso Exitoso (Hazard Unit Activada):**
  * **Dónde hacer Zoom:** Ciclos 4 a 6.
  * **Qué resaltar en la Waveform (Dibujar recuadro AZUL):**
    * Enmarca el momento en que `ForwardAE` cambia a `2'b01` (forward desde Writeback) y `ForwardBE` cambia a `2'b10` (forward desde Memory).
    * Subraya la señal `ALUResultE` calculando el valor correcto `17` (`0x11`) en el ciclo 5.
  * **Explicación de la Solución:** La Hazard Unit detecta que las instrucciones previas en MEM y WB tienen como registro destino los mismos registros fuente de la instrucción activa en EX. Reenvía los datos de forma instantánea a los multiplexores de la ALU.

---

### 📸 Captura 2: Programa de Stalling (`test_stalling.mem`)

* **Caso de Fallo (Hazard Unit Desactivada):**
  * **Dónde hacer Zoom:** Ciclos 5 y 6.
  * **Qué resaltar en la Waveform (Dibujar recuadro ROJO):**
    * Señala que `StallF` y `StallD` permanecen en `0`.
    * Subraya el `PCF` que avanza de manera continua de `0x08` a `0x0C` a `0x10` sin detenerse.
    * Enmarca `ALUResultE` en el ciclo 6 mostrando la suma errónea `0 + 5 = 5` porque el dato de memoria no se ha cargado todavía.
  * **Explicación del Fallo:** El procesador no se detiene para esperar a que termine el acceso a memoria de la instrucción `lw`. Ejecuta la instrucción `add` inmediatamente utilizando datos corruptos o antiguos.

* **Caso Exitoso (Hazard Unit Activada):**
  * **Dónde hacer Zoom:** Ciclos 5 a 7.
  * **Qué resaltar en la Waveform (Dibujar recuadro AZUL):**
    * Enmarca la señal `StallF` y `StallD` yendo a `1` en el ciclo 5.
    * Muestra que el PC en Fetch (`PCF`) se congela en `0x10` y la instrucción en Decode (`InstrD`) se queda congelada en `add x4, x3, x2`.
    * Dibuja una flecha que apunte a `FlushE` yendo a `1` en ese mismo ciclo, inyectando un `nop` (`0x00000000`) en la etapa Execute (burbuja).
    * Subraya que en el ciclo siguiente (ciclo 7), tras congelar el pipeline por 1 ciclo, `ALUResultE` calcula la suma correcta `5 + 5 = 10` (`0x0A`).
  * **Explicación de la Solución:** La Hazard Unit detecta un riesgo tipo *Load-Use*. Congela Fetch y Decode por un ciclo de reloj para permitir que la instrucción `lw` complete la lectura física de la memoria. Luego, mediante forwarding, envía el dato correcto a la ALU.

---

### 📸 Captura 3: Programa de Flushing (`test_flushing.mem`)

* **Caso de Fallo (Hazard Unit Desactivada):**
  * **Dónde hacer Zoom:** Ciclos 4 a 8.
  * **Qué resaltar en la Waveform (Dibujar recuadro ROJO):**
    * Enmarca las señales `FlushD` y `FlushE` en `0` permanentemente.
    * Muestra cómo la instrucción `addi x3, x0, 1` (`0x00100193`) fluye a lo largo de las etapas Decode y Execute sin borrarse.
    * Subraya el banco de registros mostrando que `rf[3]` cambia al valor `1`, demostrando que la instrucción en la ruta de control que debía descartarse se ejecutó por completo.
  * **Explicación del Fallo:** Al no limpiarse los registros de pipeline, las instrucciones precargadas secuencialmente continúan su ejecución normal y modifican el estado de los registros, desobedeciendo la lógica del salto tomado.

* **Caso Exitoso (Hazard Unit Activada):**
  * **Dónde hacer Zoom:** Ciclos 4 a 6.
  * **Qué resaltar en la Waveform (Dibujar recuadro AZUL):**
    * Enmarca las señales `FlushD` y `FlushE` yendo a `1` cuando `PCSrcE = 1` en el ciclo 4.
    * Señala cómo en el ciclo siguiente las señales `InstrD` e `InstrE` muestran `0x00000000` (instrucción limpia / NOP), confirmando que las instrucciones especulativas de las direcciones `0x08` y `0x0C` fueron eliminadas de las etapas del pipeline.
    * Subraya que el registro `rf[3]` mantiene su valor original `0`.
  * **Explicación de la Solución:** Cuando la etapa Execute confirma que el branch condicional es tomado (`PCSrcE = 1`), la Hazard Unit invalida instantáneamente las instrucciones en Fetch y Decode mediante las señales de borrado (`Flush`), evitando que tengan efectos en el estado de la CPU.

---

### 📸 Captura 4: Programa de Instrucciones Nuevas (`test_new_instructions.mem`)

* **Caso Exitoso (Hazard Unit Activada):**
  * **Dónde hacer Zoom:** Sección intermedia de la ejecución (del ciclo 10 al 20).
  * **Qué resaltar en la Waveform (Dibujar recuadro AZUL/VERDE):**
    * Enmarca las operaciones de la ALU (`ALUResultE`) para:
      * `LUI`: Comprueba que `ALUResultE` vale `0x12345000` pasando directamente el operando B.
      * `JALR`: Comprueba que el PC destino se calcula sumando el registro base `x3` (20) más el desplazamiento `8`, resultando en `28` (`0x1C`).
      * `BLT`: Muestra la comparación signada de `x7` (-10) y `x8` (5), y el valor de `PCSrcE` activándose en alto al cumplirse la condición $-10 < 5$.
      * `BGE`: Muestra la comparación de `x8` (5) y `x7` (-10), y el valor de `PCSrcE` activándose en alto al cumplirse la condición $5 \ge -10$.
    * Muestra los flushes asociados a cada uno de estos saltos tomados.
  * **Explicación del Programa Extra:** Este programa robusto valida todas las extensiones de control del procesador (branches condicionales complejos y saltos indirectos) operando de manera integrada con la lógica de resolución de riesgos.

---

## 4. Capturas Adicionales para la Entrega 2: Pruebas RVC

Para la segunda entrega (RVC), el evaluador buscará verificar que el descompresor en Fetch no rompa el funcionamiento segmentado:

### 📸 Captura 5: Test RVC Básico (`test_rvc_basic.mem`)
* **Qué capturar:** Ciclos 1 a 10.
* **Qué resaltar (Dibujar recuadro AZUL):**
  * En la señal `PCF`, subraya la secuencia: `0` $\rightarrow$ `2` $\rightarrow$ `4` $\rightarrow$ `8` $\rightarrow$ `A` $\rightarrow$ `10`.
  * Dibuja un círculo sobre `is_compressed` subiendo a `1` en las direcciones `0x00`, `0x02`, `0x08`, `0x0A`.
  * Enmarca `InstrF` y `InstrD` mostrando la instrucción inflada a 32 bits en tiempo real. Por ejemplo: `0x0415` (16-bit) se traduce a `0x00540413` (32-bit).

### 📸 Captura 6: Test RVC de Memoria (`test_rvc_memory.mem`)
* **Qué capturar:** Ciclos de ejecución de `c.sw` y `c.lw` (ciclos 4 a 8).
* **Qué resaltar (Dibujar recuadro AZUL):**
  * Enmarca la señal `MemWriteM` yendo a alto en la etapa MEM para `c.sw` (`0xC044`).
  * Señala la dirección de memoria `ALUResultM` en `4` y el dato de escritura `WriteDataM` in `42`.
  * Enmarca la lectura en la etapa WB, mostrando el registro de destino `rf[10]` tomando el valor `42`.

### 📸 Captura 7: Test RVC de Saltos (`test_rvc_branches.mem`)
* **Qué capturar:** Ciclos donde ocurre la bifurcación condicional comprimida `c.bnez` (dirección `0x0A`).
* **Qué resaltar (Dibujar recuadro AZUL):**
  * Enmarca la señal `PCSrcE` yendo a `1` en la etapa Execute.
  * Señala la activación de `FlushD` y `FlushE` para descartar la instrucción de la dirección `0x0C` (NOP de 32 bits).
  * Apunta al `PCF` saltando directamente a `0x10`.
