module hunit(

    // Entradas al Decode 
    input [4:0] Rs1D,
    input [4:0] Rs2D,

    // Entradas al Execute 
    input [4:0] RdE,
    input [4:0] Rs2E,
    input [4:0] Rs1E,
    input PCSrcE,
    input ResultSrcE,

    // Entradas al Memory 
    input [4:0] RdM,
    input RegWriteM,

    // Entradas al WriteBack 
    input [4:0] RdW,
    input RegWriteW,

    // Salida Fetch 
    output StallF,

    // Salida Decode
    output StallD,
    output FlushD,

    // Salida Execute
    output FlushE,


    // Salida Execute
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE

);

    // ==========================================================================
    // 1. Lógica de FORWARDING (Reenvío de datos)
    // ==========================================================================
    always_comb begin
        // Forwarding para el operando A (ForwardAE)
        if (((Rs1E == RdM) & RegWriteM) & (Rs1E != 5'b00000)) begin
            ForwardAE = 2'b10;
        end 
        else if (((Rs1E == RdW) & RegWriteW) & (Rs1E != 5'b00000)) begin
            ForwardAE = 2'b01;
        end 
        else begin
            ForwardAE = 2'b00;
        end

        // Forwarding para el operando B (ForwardBE)
        if (((Rs2E == RdM) & RegWriteM) & (Rs2E != 5'b00000)) begin
            ForwardBE = 2'b10;
        end 
        else if (((Rs2E == RdW) & RegWriteW) & (Rs2E != 5'b00000)) begin
            ForwardBE = 2'b01;
        end 
        else begin
            ForwardBE = 2'b00;
        end
    end

    // ==========================================================================
    // 2. Lógica de STALLING (Pausas por dependencia Load-Use)
    // ==========================================================================
    logic lwStall;
    
    // lwStall ocurre si la instrucción en Decode usa un registro que la 
    // instrucción en Execute (que DEBE ser un lw) va a escribir.
    assign lwStall = ((Rs1D == RdE) | (Rs2D == RdE)) & ResultSrcE;
    
    // Si hay stall, detenemos las etapas Fetch y Decode
    assign StallF = lwStall;
    assign StallD = lwStall;

    // ==========================================================================
    // 3. Lógica de FLUSHING (Limpieza por saltos y stalls)
    // ==========================================================================
    // Si ocurre un salto exitoso, borramos la instrucción que entró a Decode
    assign FlushD = PCSrcE;
    
    // Borramos la instrucción en Execute si hubo salto OR si metimos un Stall
    assign FlushE = lwStall | PCSrcE;

endmodule