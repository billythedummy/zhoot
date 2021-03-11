/* Timers for controlling when to output move command to enemy,
 * increasing speed/difficulty as time passes
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - resets the timers and game difficulty
 *
 * Outputs:
 *   move - 1 if enemy should move this clock tick, 0 otherwise
*/
module enemy_move_ctrl (
    input logic clk, reset,
    output logic move
);
    localparam MOVE_PERIOD_BASE_50M = 20_000_000;
    localparam LOG_MOVE_PERIOD_50M = $clog2(MOVE_PERIOD_BASE_50M);
    localparam MOVE_PERIOD_MAX_SUB_50M = 18_000_000;
    // fastest possible period is MOVE_PERIOD_BASE_50M - MOVE_PERIOD_MAX_SUB_50M
    localparam LOG_MOVE_PERIOD_INC_DELAY_50M = 6;
    localparam MOVE_PERIOD_INC_DELAY_50M = 2**LOG_MOVE_PERIOD_INC_DELAY_50M-1; // decrement move period every this ticks

    logic to_zero;
    assign to_zero = cnt >= MOVE_PERIOD_BASE_50M - move_period_sub;

    logic [LOG_MOVE_PERIOD_50M-1:0] cnt;
    always_ff @(posedge clk)
        if (reset | to_zero) cnt <= LOG_MOVE_PERIOD_50M'(0);
        else cnt <= cnt + LOG_MOVE_PERIOD_50M'(1);

    logic [LOG_MOVE_PERIOD_INC_DELAY_50M-1:0] move_period_outer_cnt;
    upctr #(.W(LOG_MOVE_PERIOD_INC_DELAY_50M), .L(MOVE_PERIOD_INC_DELAY_50M)) move_period_outer_ctr (
        .clk, .reset,
        .inc(1'b1), .cnt(move_period_outer_cnt)
    );
    logic [LOG_MOVE_PERIOD_50M-1:0] move_period_sub;
    // saturate at MOVE_PERIOD_MAX_SUB_50M
    upctr #(.W(LOG_MOVE_PERIOD_50M), .L(MOVE_PERIOD_MAX_SUB_50M)) move_period_sub_ctr (
        .clk, .reset,
        .inc(move_period_outer_cnt == MOVE_PERIOD_INC_DELAY_50M & move_period_sub != MOVE_PERIOD_MAX_SUB_50M),
        .cnt(move_period_sub)
    );

    assign move = to_zero;
endmodule