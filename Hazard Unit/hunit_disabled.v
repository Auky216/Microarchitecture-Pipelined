// ============================================================================
// HAZARD UNIT DESHABILITADA (Para demostrar errores sin manejo de riesgos)
// ============================================================================
// Este modulo tiene EXACTAMENTE las mismas entradas y salidas que hunit.v,
// pero TODAS las salidas están forzadas a 0. Esto significa:
//   - ForwardAE/BE = 00 -> No hay forwarding (siempre lee del registro)
//   - StallF/StallD  = 0  -> Nunca se congela el pipeline
//   - FlushD/FlushE  = 0  -> Nunca se vacía el pipeline (excepto por PCSrcE para Fetch)

module hunit_disabled (
  input  logic [4:0] Rs1E, Rs2E,
  input  logic [4:0] RdM, RdW,
  input  logic       RegWriteM, RegWriteW,
  input  logic [4:0] Rs1D, Rs2D, RdE,
  input  logic       ResultSrcE0,
  input  logic       PCSrcE,
  output logic [1:0] ForwardAE, ForwardBE,
  output logic       StallF, StallD,
  output logic       FlushD, FlushE
);

  // Sin forwarding: siempre usa el valor del registro (puede ser viejo/incorrecto)
  assign ForwardAE = 2'b00;
  assign ForwardBE = 2'b00;

  // Sin stalls: el pipeline nunca se detiene ante un Load-Use hazard
  assign StallF = 1'b0;
  assign StallD = 1'b0;

  // Sin flush por stall, pero mantenemos el flush por branch para que el PC
  // al menos pueda saltar (si no, el beq nunca redirige y el programa se cuelga)
  assign FlushD = PCSrcE;
  assign FlushE = PCSrcE;

endmodule
