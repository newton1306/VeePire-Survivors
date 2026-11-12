`timescale 1ns / 1ps
// Memory primitives loaded from .mem hex files

// Single-port Block RAM ROM (1 clock read latency)
module rom_1p #(
    parameter DW = 6, AW = 12, DEPTH = (1 << AW),
    parameter FILE = ""
) (
    input  wire          clk,
    input  wire [AW-1:0] addr,
    output reg  [DW-1:0] q = 0
);
    (* rom_style = "block" *) reg [DW-1:0] mem [0:DEPTH-1];
    initial $readmemh(FILE, mem);
    always @(posedge clk) q <= mem[addr];
endmodule

// Dual-port Block RAM ROM (Port A: renderer, Port B: physics collision)
module rom_dp #(
    parameter DW = 4, AW = 12, DEPTH = (1 << AW),
    parameter FILE = ""
) (
    input  wire          clk,
    input  wire [AW-1:0] addr_a,
    output reg  [DW-1:0] q_a = 0,
    input  wire [AW-1:0] addr_b,
    output reg  [DW-1:0] q_b = 0
);
    (* rom_style = "block" *) reg [DW-1:0] mem [0:DEPTH-1];
    initial $readmemh(FILE, mem);
    always @(posedge clk) q_a <= mem[addr_a];
    always @(posedge clk) q_b <= mem[addr_b];
endmodule

// Distributed LUT ROM (1 clock read latency)
module rom_lut #(
    parameter DW = 12, AW = 8, DEPTH = (1 << AW),
    parameter FILE = ""
) (
    input  wire          clk,
    input  wire [AW-1:0] addr,
    output reg  [DW-1:0] q = 0
);
    (* rom_style = "distributed" *) reg [DW-1:0] mem [0:DEPTH-1];
    initial $readmemh(FILE, mem);
    always @(posedge clk) q <= mem[addr];
endmodule
