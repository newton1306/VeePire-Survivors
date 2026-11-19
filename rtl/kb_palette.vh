// Auto-generated 16-color 12-bit palette for Guide Page 3 Real White Keyboard Keycaps
function [11:0] kb_palette;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  kb_palette = 12'h000;
            4'd1:  kb_palette = 12'hFFF;
            4'd2:  kb_palette = 12'hEEE;
            4'd3:  kb_palette = 12'hCCD;
            4'd4:  kb_palette = 12'h89A;
            4'd5:  kb_palette = 12'h112;
            4'd6:  kb_palette = 12'h2DF;
            4'd7:  kb_palette = 12'hFD2;
            4'd8:  kb_palette = 12'h4F6;
            4'd9:  kb_palette = 12'hF5B;
            4'd10: kb_palette = 12'hF54;
            4'd11: kb_palette = 12'hCCD;
            4'd12: kb_palette = 12'h234;
            4'd13: kb_palette = 12'h457;
            4'd14: kb_palette = 12'h58B;
            default: kb_palette = 12'h000;
        endcase
    end
endfunction
