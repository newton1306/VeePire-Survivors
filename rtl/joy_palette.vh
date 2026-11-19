// Auto-generated 16-color 12-bit palette for joy_pixel (with real_joystick button colors)
function [11:0] joy_palette;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  joy_palette = 12'h000;
            4'd1:  joy_palette = 12'hFFF;
            4'd2:  joy_palette = 12'hCDD;
            4'd3:  joy_palette = 12'h2E6; // Button 1: Green
            4'd4:  joy_palette = 12'hCCD;
            4'd5:  joy_palette = 12'hF44; // Button 2: Red
            4'd6:  joy_palette = 12'h3BF; // Button 3: Blue
            4'd7:  joy_palette = 12'h9AB;
            4'd8:  joy_palette = 12'h679;
            4'd9:  joy_palette = 12'h456;
            4'd10: joy_palette = 12'hE5B; // Button 4: Pink
            4'd11: joy_palette = 12'h222;
            4'd12: joy_palette = 12'h334; // Dark Select/Start
            4'd13: joy_palette = 12'h212;
            4'd14: joy_palette = 12'h122;
            4'd15: joy_palette = 12'h111;
            default: joy_palette = 12'h000;
        endcase
    end
endfunction
