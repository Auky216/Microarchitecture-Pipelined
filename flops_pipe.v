module flopenr #(parameter WIDTH = 8) (
    input  wire             clk, reset, en,
    input  wire [WIDTH-1:0] d, 
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        $display("Time=%0t flopenr clk=%b reset=%b en=%b d=%h q_before=%h", $time, clk, reset, en, d, q);
        if (reset) q <= 0;
        else if (en) q <= d;
    end
endmodule

module flopenrc #(parameter WIDTH = 8) (
    input  wire             clk, reset, en, clear,
    input  wire [WIDTH-1:0] d, 
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset) q <= 0;
        else if (clear) q <= 0;
        else if (en) q <= d;
    end
endmodule

module floprc #(parameter WIDTH = 8) (
    input  wire             clk, reset, clear,
    input  wire [WIDTH-1:0] d, 
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset) q <= 0;
        else if (clear) q <= 0;
        else q <= d;
    end
endmodule
