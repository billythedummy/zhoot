module gun #(parameter BIN_W=6, BIN_SIZE=10) (
    input logic clk, reset, start,
    input logic [9:0] x,
    input logic [8:0] y,
    input logic [BIN_W-1:0] bin_x,
    input logic [BIN_W-1:0] bin_y,
    input logic button_left,
    output logic [9:0] shoot_x,
    output logic [8:0] shoot_y,
    output logic shot,
    output logic render
);
    localparam CD_TICKS_50M = 19_999_999;
    localparam CROSSHAIR_RADIUS = 32;
    localparam MAX_H = 480;

    enum {S_IDLE, S_CD} ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_IDLE;
        else ps <= ns;

    // convert bin coords to screen coords
    logic [9:0] center_mouse_x;
    assign center_mouse_x = 10'(bin_x * BIN_SIZE);
    logic [9:0] top_left_mouse_x;
    assign top_left_mouse_x = center_mouse_x - 10'(CROSSHAIR_RADIUS);
    logic [8:0] center_mouse_y;
    // mouse-y is inverted
    assign center_mouse_y = 9'(MAX_H) - 9'(bin_y * BIN_SIZE);
    logic [8:0] top_left_mouse_y;
    assign top_left_mouse_y = center_mouse_y - 9'(CROSSHAIR_RADIUS);

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
endmodule

module gun_test();
    logic clk, reset, start;
    logic [9:0] x, shoot_x;
    logic [8:0] y, shoot_y;
    logic [5:0] bin_x, bin_y;
    logic button_left;
    logic shot, render;

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