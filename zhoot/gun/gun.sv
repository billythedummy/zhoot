/* Top level controller for gun. Receives input from PS/2 driver, does state management and rendering
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - global reset
 *   start - start the game
 *   x - x-coordinate of current pixel to render
 *   y - y-coordinate of current pixel to render
 *   bin_x - x-index of current mouse bin
 *   bin_y - y-index of current mouse bin
 *   button_left - 1 if LMB clicked
 *
 * Outputs:
 *   shoot_x - x-coordinate of pixel being shot at
 *   shoot_y - y-coordinate of pixel being shot at
 *   shot - did the user shoot in this clock cycle
 *   render - 1 if pixel (x, y) is to be rendered as an enemy, 0 if black
 *   cd - 1 if gun is currently on cooldown, 0 otherwise
*/
module gun #(parameter BIN_W=6, BIN_SIZE=10) (
    input logic clk, reset,
    input logic [9:0] x,
    input logic [8:0] y,
    input logic [BIN_W-1:0] bin_x,
    input logic [BIN_W-1:0] bin_y,
    input logic button_left,
    output logic [9:0] shoot_x,
    output logic [8:0] shoot_y,
    output logic shot,
    output logic render,
    output logic cd
);
    localparam CD_TICKS_50M = 9_999_999;
    localparam CROSSHAIR_RADIUS = 32;
    localparam MAX_H = 480;

    enum {S_IDLE, S_CD} ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_IDLE;
        else ps <= ns;

    // convert bin coords to screen coords
    logic [9:0] top_left_mouse_x;
    assign top_left_mouse_x = 10'(bin_x * BIN_SIZE);
    logic [9:0] center_mouse_x;
    assign center_mouse_x = top_left_mouse_x + 10'(CROSSHAIR_RADIUS);
    // mouse-y is inverted
    logic [8:0] top_left_mouse_y;
    assign top_left_mouse_y = 9'(MAX_H) - 9'(bin_y * BIN_SIZE);
    logic [8:0] center_mouse_y;
    assign center_mouse_y = top_left_mouse_y + 9'(CROSSHAIR_RADIUS);

    // cooldown counter
    logic [$clog2(CD_TICKS_50M)-1 : 0] cd_cnt;
    upctr #(.W($clog2(CD_TICKS_50M)), .L(CD_TICKS_50M)) cd_ctr (
        .clk,
        .reset(shot),
        .inc(ps == S_CD),
        .cnt(cd_cnt)
    );
    
    // renderer
    crosshair_render cr (
        .clk,
        .x, .y,
        .x_me(top_left_mouse_x), .y_me(top_left_mouse_y),
        .render
    );

    // state transition
    always_comb
        case (ps)
            S_IDLE: ns = shot ? S_CD : S_IDLE;
            S_CD: ns = (cd_cnt == CD_TICKS_50M) ? S_IDLE : S_CD;
        endcase

    assign shoot_x = center_mouse_x;
    assign shoot_y = center_mouse_y;
    assign shot = ps == S_IDLE & button_left;
    assign cd = ps == S_CD;
endmodule

module gun_test();
    logic clk, reset;
    logic [9:0] x, shoot_x;
    logic [8:0] y, shoot_y;
    logic [5:0] bin_x, bin_y;
    logic button_left;
    logic shot, render, cd;

    gun dut (.*);

    // Setup clock
	parameter t = 10;
	initial begin
        clk <= 0;
        forever #(t/2) clk <= ~clk;
    end

    initial begin
        bin_x = 6; bin_y = 9;
        @(posedge clk); #1;
        assert(shoot_x == 10'd60); assert(shoot_y == 9'd390);
        button_left = 1;
        @(posedge clk); #1;
        assert(shot);
        // better to check cd behaviour with a seq
        @(posedge clk); #1;
        assert(!shot);
        $stop;
    end
endmodule