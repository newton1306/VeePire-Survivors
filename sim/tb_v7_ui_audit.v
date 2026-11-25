`timescale 1ns / 1ps

module tb_v7_ui_audit;
    reg clk = 0;
    always #20 clk = ~clk;

    reg rst = 1;
    wire [9:0] vga_x, vga_y;
    wire       vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_sync (.clk(clk), .rst(rst), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on));

    wire [12:0] map_addr_a;
    reg  [3:0]  map_tile_a = 4'd0;

    reg  [1:0] control_mode = 2'b10;
    reg  [2:0] game_state   = 3'd0;
    reg  [2:0] room_phase   = 3'd0;
    reg  [2:0] help_page    = 3'd2;
    reg        paused       = 1'b0;
    reg  [1:0] quiz_ans_slot = 2'd0;
    reg  [1:0] quiz_cursor   = 2'd1;
    reg  [2:0] quiz_gate     = 3'd3;

    wire [3:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;

    vga_renderer_v2 u_renderer (
        .clk(clk), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on),
        .map_addr_a(map_addr_a), .map_tile_a(map_tile_a),
        .sw(16'h0000), .tilt_dx(3'sd0), .tilt_dy(3'sd0),
        .control_mode(control_mode), .joy_link_ok(1'b1), .p2_active(1'b0),
        .zoom_lvl(7'd0), .zoom_out(1'b0), .enemies_left(5'd4),
        .game_state(game_state), .cut_id(2'd0), .cut_timer(8'd0), .wave(4'd1),
        .zone2_open(1'b0), .zone3_open(1'b0),
        .px(11'd160), .py(10'd160), .dash_gx(11'd0), .dash_gy(10'd0),
        .p2x(11'd220), .p2y(10'd160), .p2_dash_gx(11'd0), .p2_dash_gy(10'd0),
        .p2_mirror(1'b0), .p2_walk_frame(1'b0), .p2_dash_timer(5'd0),
        .cam_x(11'd0), .cam_y(10'd0),
        .hp(5'd24), .hp2(5'd24), .exp(6'd10), .stage(2'd1), .score_bcd(24'h001250),
        .p1_weapon(3'd0), .p2_weapon(3'd1), .hero_cursor(1'b0),
        .chrono_energy(7'd50), .chrono_active(1'b0),
        .mirror(1'b0), .walk_frame(1'b0),
        .dash_timer(5'd0), .invuln_timer(6'd0), .p2_invuln(6'd0), .evolve_flash(5'd0),
        .combo_cnt(7'd0), .shake_mag(4'd0), .p1_nova(1'b0), .p2_nova(1'b0),
        .pet_active(1'b0), .blades_active(1'b0), .aura_active(1'b0),
        .blade0_x(11'd0), .blade0_y(10'd0), .blade1_x(11'd0), .blade1_y(10'd0),
        .p2_blade0_x(11'd0), .p2_blade0_y(10'd0), .p2_blade1_x(11'd0), .p2_blade1_y(10'd0),
        .pet_bx(11'd0), .pet_by(10'd0), .pet_b_act(1'b0),
        .en_x_vec(176'd0), .en_y_vec(160'd0), .en_type_vec(48'd0),
        .en_alive_vec(16'd0), .en_hp_vec(64'd0), .en_tier_vec(32'd0),
        .col_x_vec(132'd0), .col_y_vec(120'd0), .col_type_vec(12'd0), .col_alive_vec(12'd0),
        .drop_x_vec(44'd0), .drop_y_vec(40'd0), .drop_z_vec(28'd0),
        .drop_type_vec(8'd0), .drop_active_vec(4'd0), .drop_boom_vec(20'd0),
        .sp_x_vec(132'd0), .sp_y_vec(120'd0), .sp_alive_vec(12'd0),
        .p1_slash_x(11'd0), .p1_slash_y(10'd0), .p1_slash_t(4'd0), .p1_slash_dx(2'sd1), .p1_slash_dy(2'sd0),
        .p2_slash_x(11'd0), .p2_slash_y(10'd0), .p2_slash_t(4'd0), .p2_slash_dx(2'sd1), .p2_slash_dy(2'sd0),
        .lock_x(11'd0), .lock_y(10'd0), .lock_valid(1'b0),
        .eb_x_vec(88'd0), .eb_y_vec(80'd0), .eb_active_vec(8'd0),
        .pb_x_vec(88'd0), .pb_y_vec(80'd0), .pb_dir_vec(16'd0), .pb_active_vec(8'd0),
        .boss_x(11'd0), .boss_y(10'd0), .boss_hp(8'd0), .boss_kind(2'd0),
        .boss_active(1'b0), .boss_locked(1'b0), .boss_enraged(1'b0),
        .laser_state(2'd0), .laser_y(10'd0),
        .hero_sel_l(2'd0), .hero_sel_r(2'd1),
        .room_phase(room_phase), .wave_banner_t(7'd0), .door_slam_t(6'd0),
        .door_slide(5'd0), .quiz_gate(quiz_gate), .quiz_cursor(quiz_cursor),
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(7'd0), .boss_trans_t(8'd0), .outfit_cut_t(8'd0), .paused(paused),
        .temp_fever(1'b0), .mic_roar(1'b0), .help_page(help_page), .sonic_wave_t(5'd0), .sonic_radius(9'd0),
        .mouse_x(9'd160), .mouse_y(8'd120), .mouse_lmb(1'b0),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    task capture_ppm;
        input [8*64-1:0] fname;
        integer fd, pcnt;
        begin
            wait (vga_y == 10'd482);
            @(posedge clk);
            fd = $fopen(fname, "w");
            $fwrite(fd, "P3\n640 480\n255\n");
            pcnt = 0;
            while (pcnt < 307200) begin
                @(posedge clk);
                if (u_renderer.vid_3) begin
                    $fwrite(fd, "%0d %0d %0d ", VGA_R * 17, VGA_G * 17, VGA_B * 17);
                    pcnt = pcnt + 1;
                    if ((pcnt % 16) == 0) $fwrite(fd, "\n");
                end
            end
            $fclose(fd);
            $display("[PPM] Captured %0s (%0d pixels)", fname, pcnt);
        end
    endtask

    initial begin
        repeat (20) @(posedge clk);
        rst = 0;

        // 1. Joystick Guide Page 2 (D-pad MOVE line fix)
        game_state = 3'd0; paused = 1'b0; help_page = 2'd2; control_mode = 2'b10;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_guide_p2.ppm");

        // 2. Joy Pause Page 2 (PAUSED pill + [SEL] MENU row 2, NO yellow text!)
        game_state = 3'd2; paused = 1'b1; help_page = 2'd2; control_mode = 2'b10;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_pause_joy.ppm");

        // 3. KB Pause Page 3 (PAUSED pill + [ESC] RESUME row 2, NO yellow text!)
        game_state = 3'd2; paused = 1'b1; help_page = 2'd3; control_mode = 2'b01;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_pause_kb.ppm");

        // 4. Game Over Joy (Button (3) RETRY + [D-Pad] MENU)
        game_state = 3'd4; paused = 1'b0; help_page = 2'd0; control_mode = 2'b10;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_gameover_joy.ppm");

        // 5. Game Over KB ([SPC] RETRY + [A][D] MENU)
        game_state = 3'd4; paused = 1'b0; help_page = 2'd0; control_mode = 2'b01;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_gameover_kb.ppm");

        // 6. Logic Gate Quiz Joy (Slot 11 [D-Pad U/D] PICK + (3) OK)
        game_state = 3'd2; room_phase = 3'd3; paused = 1'b0; help_page = 2'd0; control_mode = 2'b10;
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v7_quiz_joy.ppm");

        $display("=== ALL V7 UI AUDIT CAPTURES DONE! ===");
        $finish;
    end
endmodule
