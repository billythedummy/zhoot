/* Top level controller for scoreboard. State management and rendering
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - reset score to 0
 *   killed - 1 if an enemy was killed in this clock cycle, 0 otherwise
 *   x - x-coordinate of current pixel to render
 *   y - y-coordinate of current pixel to render
 *
 * Outputs:
 *   render - 1 if pixel (x, y) is to be rendered as an enemy, 0 if black
*/
module score (
    input logic clk, reset,
    input logic killed,
    input logic [9:0] x,
    input logic [8:0] y,
    output logic render
);
    localparam N_DIGITS = 3;
    localparam TOP_LEFT_X = 4;
    localparam TOP_LEFT_Y = 4;
    localparam SCORETXT_W = 128;
    localparam DIGIT_W = 16;

    logic render_scoretxt;
    scoretxt_render #(.TOP_LEFT_X(TOP_LEFT_X), .TOP_LEFT_Y(TOP_LEFT_Y)) txt (.clk, .x, .y, .render(render_scoretxt));

    logic [3:0] cnt [N_DIGITS-1:0];
    logic [N_DIGITS-1:0] overflow;
    logic [N_DIGITS-1:0] render_digits;
    logic [N_DIGITS-1:0] max_all;
    logic max;
    assign max = &max_all;

    // ones
    upctr #(.W(4), .L(9)) ones_ctr (.clk, .reset, .inc(killed & ~max), .cnt(cnt[0]));
    digit_render #(.TOP_LEFT_X(TOP_LEFT_X + SCORETXT_W + (N_DIGITS-1)*DIGIT_W), .TOP_LEFT_Y(TOP_LEFT_Y)) ones_dr (
        .clk, .x, .y,
        .digit(cnt[0]), .render(render_digits[0])
    );
    assign max_all[0] = cnt[0] == 4'd9;
    assign overflow[0] = killed & max_all[0];

    genvar i;
    generate
        for (i = 1; i < N_DIGITS; i++) begin : gen_digits
            upctr #(.W(4), .L(9)) ctr (.clk, .reset, .inc(overflow[i-1] & ~max), .cnt(cnt[i]));
            digit_render #(.TOP_LEFT_X(TOP_LEFT_X + SCORETXT_W + (N_DIGITS-1-i)*DIGIT_W), .TOP_LEFT_Y(TOP_LEFT_Y)) ones_dr (
                .clk, .x, .y,
                .digit(cnt[i]), .render(render_digits[i])
            );
            assign max_all[i] = cnt[i] == 4'd9;
            assign overflow[i] = overflow[i-1] & max_all[i];
        end
    endgenerate

    assign render = (|render_digits) | render_scoretxt;
endmodule

module score_test ();
    logic clk, reset, killed, render;
    logic [9:0] x;
    logic [8:0] y;

    score dut (.*);

        // Setup clock
	parameter t = 10;
	initial begin
        clk <= 0;
        forever #(t/2) clk <= ~clk;
    end

    integer i, j, k;
    initial begin
        // test: check overflow and saturating behaviour of counters
        reset = 1;
        @(posedge clk); #1;
        reset = 0; killed = 1;
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                for (int k = 0; k < 10; k++) begin
                    #1;
                    assert(dut.cnt[0] == 4'(k));
                    assert(dut.cnt[1] == 4'(j));
                    assert(dut.cnt[2] == 4'(i));
                    @(posedge clk);
                end
            end
        end
        #1;
        // test saturation
        @(posedge clk); @(posedge clk); @(posedge clk);
        #1;
        assert(dut.cnt[0] == 4'd9);
        assert(dut.cnt[1] == 4'd9);
        assert(dut.cnt[2] == 4'd9);
        $stop;
    end
endmodule