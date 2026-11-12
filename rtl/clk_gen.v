`timescale 1ns / 1ps
// 100 MHz -> 25 MHz pixel clock for VGA 640x480 @ 60 Hz
module clk_gen (
    input  wire clk100,
    output wire clk25,
    output wire locked
);
    wire clkfb, clk25_unbuf;

    MMCME2_BASE #(
        .CLKIN1_PERIOD    (10.0),
        .CLKFBOUT_MULT_F  (8.0),
        .DIVCLK_DIVIDE    (1),
        .CLKOUT0_DIVIDE_F (32.0)
    ) u_mmcm (
        .CLKIN1   (clk100),
        .CLKFBIN  (clkfb),
        .CLKFBOUT (clkfb),
        .CLKOUT0  (clk25_unbuf),
        .LOCKED   (locked),
        .PWRDWN   (1'b0),
        .RST      (1'b0),
        .CLKFBOUTB(), .CLKOUT0B(), .CLKOUT1(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
        .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6()
    );

    BUFG u_bufg (.I(clk25_unbuf), .O(clk25));
endmodule
