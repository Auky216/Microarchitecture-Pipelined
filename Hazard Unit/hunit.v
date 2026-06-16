module hunit (
  // Entradas para Forwarding (Reenvío)
  input  logic [4:0] Rs1E, Rs2E,
  input  logic [4:0] RdM, RdW,
  input  logic       RegWriteM, RegWriteW,
  
  // Entradas para Riesgos de Datos (Load Hazards)
  input  logic [4:0] Rs1D, Rs2D, RdE,
  input  logic       ResultSrcE0, // Bit 0 de ResultSrcE (indica que es un Load)
  
  // Entrada para Riesgos de Control (Branch Hazards)
  input  logic       PCSrcE,
  
  // Salidas de Forwarding
  output logic [1:0] ForwardAE, ForwardBE,
  
  // Salidas de Stalls (Burbujas / Detenciones)
  output logic       StallF, StallD,
  
  // Salidas de Flush (Vaciado de etapas)
  output logic       FlushD, FlushE
);

  logic lwStall;

  // ==========================================================================
  // 1. FORWARDING LOGIC (Lógica de Reenvío)
  // ==========================================================================
  // Resuelve Data Hazards reenviando datos de Memory o Writeback hacia Execute

  always_comb begin
    // Forwarding para el operando A (ForwardAE)
    if (((Rs1E == RdM) & RegWriteM) & (Rs1E != 5'b00000)) begin
        ForwardAE = 2'b10;
    end else if (((Rs1E == RdW) & RegWriteW) & (Rs1E != 5'b00000)) begin
        ForwardAE = 2'b01;
    end else begin
        ForwardAE = 2'b00;
    end
    
    // Forwarding para el operando B (ForwardBE)
    if (((Rs2E == RdM) & RegWriteM) & (Rs2E != 5'b00000)) begin
        ForwardBE = 2'b10;
    end else if (((Rs2E == RdW) & RegWriteW) & (Rs2E != 5'b00000)) begin
        ForwardBE = 2'b01;
    end else begin
        ForwardBE = 2'b00;
    end
  end

  // ==========================================================================
  // 2. STALL LOGIC (Lógica de Detención por Load)
  // ==========================================================================
  // Se detiene el pipeline (Stall) cuando una instrucción en Execute es un Load 
  // (ResultSrcE0 == 1) y su registro destino (RdE) es usado por la instrucción 
  // en Decode (Rs1D o Rs2D).
  
  assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
  
  assign StallF = lwStall;
  assign StallD = lwStall;

  // ==========================================================================
  // 3. FLUSH LOGIC (Lógica de Vaciado)
  // ==========================================================================
  // Se vacía Decode (FlushD) si ocurre un salto efectivo (PCSrcE == 1).
  // Se vacía Execute (FlushE) si ocurre un salto o si hubo un stall por Load.
  
  assign FlushD = PCSrcE;
  assign FlushE = lwStall | PCSrcE;

endmodule
