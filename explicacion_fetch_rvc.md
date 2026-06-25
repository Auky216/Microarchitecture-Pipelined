# Integración de la Extensión RVC (16-bits) en la Etapa de Fetch

Este documento explica a detalle y paso a paso las modificaciones realizadas en el archivo `fetch.v` para soportar las instrucciones comprimidas de 16 bits (Extensión 'C'), manteniendo la compatibilidad con el resto del pipeline de 32 bits.

## 1. El Problema Original (El "Antes")
En un procesador RISC-V tradicional de 32 bits (RV32I), la etapa de Fetch es extremadamente sencilla. El Program Counter (PC) avanza siempre de 4 en 4 bytes, y la memoria devuelve directamente la instrucción de 32 bits.

**Código Anterior (`fetch.v` Base):**
```verilog
// Incremento rígido de PC + 4
adder pcadd (.a(PCF), .b(32'd4), .y(PCPlus4F));

// Lectura directa de memoria
imem imem (.a(PCF), .rd(InstrF));
```
El problema es que con la extensión 'C', las instrucciones pueden medir 16 bits (2 bytes). Esto causa dos grandes retos:
1. **Alineación:** El PC ahora puede apuntar a un número de media palabra (ej. `0x2`, `0x6`), por lo que al leer de la memoria (que lee palabras completas de 32 bits), nuestra instrucción de 16 bits puede quedar "atrapada" en la parte alta.
2. **Compatibilidad:** Si le entregamos 16 bits a la etapa de Decode (la cual está alambrada para decodificar 32 bits), el pipeline entero fallará.

---

## 2. La Solución Paso a Paso (El "Después")

Para solucionar esto, el `fetch.v` fue reescrito integrando un **descompresor combinacional** y un sistema de **alineación dinámica**.

### Paso A: Leer de la memoria y Alinear
La memoria `imem` sigue entregando 32 bits (`raw_imem_data`), pero ahora revisamos si el PC termina en `2` o `6` (revisando el bit `PCF[1]`). Si es así, desplazamos los 16 bits superiores hacia abajo.

```verilog
wire [31:0] raw_imem_data;
imem imem (.a(PCF), .rd(raw_imem_data));

// ALINEACIÓN: Si PCF[1] es 1 (ej. 0x2), la instrucción está en la parte alta [31:16].
wire [31:0] actual_instr;
assign actual_instr = PCF[1] ? {16'b0, raw_imem_data[31:16]} : raw_imem_data;
```

### Paso B: Evaluar y Descomprimir
Extraemos siempre los primeros 16 bits y se los mandamos al nuevo módulo `decompressor`. Este módulo nos dice si la instrucción efectivamente es comprimida (`is_compressed`) y, de ser así, nos devuelve de inmediato su equivalente traducido a 32 bits.

```verilog
wire [15:0] cinstr;
wire [31:0] decompressed_instr;
wire is_compressed;

assign cinstr = actual_instr[15:0];

// Instanciación del descompresor combinacional
decompressor decomp (
    .cinstr(cinstr),
    .outstr(decompressed_instr),
    .is_compressed(is_compressed)
);
```

### Paso C: El Multiplexor del Engaño
Aquí ocurre la magia. Dependiendo de si la instrucción era de 16 bits o no, elegimos qué mandarle a la etapa de Decode. Al enviarle siempre 32 bits válidos (expandidos por el descompresor), el resto del procesador **no requiere ninguna modificación**.

```verilog
// Si es de 16 bits, enviamos la versión expandida (32 bits).
// Si es de 32 bits, enviamos la original leída.
assign InstrF = is_compressed ? decompressed_instr : actual_instr;
```

### Paso D: Avance Dinámico del PC
Finalmente, el sumador del PC ya no suma `+4` rígidamente. Ahora suma `+2` si acabamos de leer una instrucción comprimida, o `+4` si fue una normal.

```verilog
wire [31:0] pc_increment;

// Incremento dinámico: +2 o +4
assign pc_increment = is_compressed ? 32'd2 : 32'd4;

// Sumador actualizado
adder pcadd (.a(PCF), .b(pc_increment), .y(PCPlus4F)); // Conserva el nombre PCPlus4F para compatibilidad
```

## Resumen del Flujo de Datos
1. Se lee la memoria de instrucciones de 32 en 32 bits.
2. Se ajustan los bits si el PC estaba desalineado en `0x2` o `0x6`.
3. Se detecta si es comprimida analizando los 2 últimos bits.
4. Se traduce a la sintaxis original RV32I en tiempo cero (combinacionalmente).
5. Se le entrega a `Decode` la versión pura de 32 bits.
6. El Program Counter se actualiza sumando el tamaño real de la instrucción (2 o 4 bytes).
