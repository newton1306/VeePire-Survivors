`timescale 1ns / 1ps
// VGA 640 x 480 @ 60 Hz timing generator (25 MHz pixel clock)
module vga_sync (
    input  wire       clk,
    input  wire       rst,
    output reg  [9:0] x = 10'd0,
    output reg  [9:0] y = 10'd0,
    output wire       hsync,
    output wire       vsync,
    output wire       video_on
);
    localparam H_VISIBLE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48;
    localparam V_VISIBLE = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33;
    localparam H_TOTAL = H_VISIBLE + H_FP + H_SYNC + H_BP; // 800
    localparam V_TOTAL = V_VISIBLE + V_FP + V_SYNC + V_BP; // 525

    wire       x_end  = (x == H_TOTAL - 1);
    wire       y_end  = (y == V_TOTAL - 1);

    assign hsync    = ~(x >= (H_VISIBLE + H_FP) && x < (H_VISIBLE + H_FP + H_SYNC));
    assign vsync    = ~(y >= (V_VISIBLE + V_FP) && y < (V_VISIBLE + V_FP + V_SYNC));
    assign video_on = (x < H_VISIBLE && y < V_VISIBLE);

    always @(posedge clk) begin
        if (rst) begin
            x <= 10'd0;
            y <= 10'd0;
        end else begin
            x <= x_end ? 10'd0 : x + 10'd1;
            if (x_end)
                y <= y_end ? 10'd0 : y + 10'd1;
        end
    end
endmodule
