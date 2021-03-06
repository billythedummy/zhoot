import enemy_def::*;

/* A single enemy
 * state management, shot detection and rendering
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - resets this module to S_DEAD
 *   x      - x-coordinate of current pixel to render
 *   shoot_x - x-coordinate of pixel being shot at
 *   y - y-coordinate of current pixel to render
 *   shoot_y - y-coordinate of pixel being shot at
 *   shot - did the user shoot in this clock cycle
 *   shot_blocked - 1 if current shot is blocked by another enemy, 0 otherwise
 *   spawn - try to spawn this enemy
 *   write_x_d - x_coordinate to spawn with
 *   move - 1 to move downwards 
 *
 * Outputs:
 *   curr_y - this enemy's current y coordinate
 *   render - 1 if pixel (x, y) is to be rendered as an enemy, 0 if black
 *   killed - 1 if this enemy was killed this clock cycle, 0 otherwise
 *   alive - 1 if this enemy is currently alive
 *   spawned - 1 if this enemy was spawned this clock cycle
*/
module enemy (
    input logic clk, reset,
    // render coords
    input logic [9:0] x, shoot_x,
    input logic [8:0] y, shoot_y,
    input logic shot, shot_blocked,
    // spawn inputs
    input logic spawn,
    // assumes write_x_d is in range
    input logic [9:0] write_x_d,
    // command enemy to move down
    input logic move,
    output logic [8:0] curr_y,
    output logic render, killed,
    output logic alive, spawned
);
    localparam START_Y = 9'd48;
    localparam STEP_Y = 9'd10; // move this many px downwards when move=1
    localparam DYING_W = 25;
    localparam DYING_TICKS = 24_999_999; // how many ticks to hold dying image for

    logic respawn;
    assign respawn = spawn & ~alive;

    enemy_state_t ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_DEAD;
        else ps <= ns;
    
    always_comb
        case (ps)
            S_DEAD: ns = respawn ? S_ALIVE : S_DEAD;
            S_ALIVE: ns = killed ? S_DYING : S_ALIVE;
            S_DYING: if (respawn) ns = S_ALIVE;
                     else ns = dying_finished ? S_DEAD : S_DYING;
        endcase

    // center coordinate registers
    logic [9:0] x_ff;
    always_ff @(posedge clk)
        if (respawn) x_ff <= write_x_d;
        else x_ff <= x_ff;
    
    logic [8:0] y_ff;
    always_ff @(posedge clk)
        if (respawn) y_ff <= START_Y;
        else if (alive & move) y_ff <= y_ff + STEP_Y;
        else y_ff <= y_ff;

    // dying animation
    logic dying_finished;
    wire [DYING_W-1 : 0] dying_cnt;
    upctr #(.W(DYING_W), .L(DYING_TICKS)) dying_ctr (
        .clk, .reset(killed),
        .inc(1'b1), .cnt(dying_cnt)
    );
    assign dying_finished = dying_cnt == DYING_TICKS;

    // render
    logic [9:0] curr_x;
    assign curr_x = x_ff;
    enemy_render er (
        .clk, .x, .y,
        .state(ps), 
        .x_me(curr_x - HALF_ENEMY_D), .y_me(curr_y - HALF_ENEMY_D),
        .render
    );

    // outputs
    assign curr_y = y_ff;
    assign killed = alive & shot & ~shot_blocked
        & shoot_x >= curr_x - HALF_ENEMY_D
        & shoot_x < curr_x + HALF_ENEMY_D
        & shoot_y >= curr_y - HALF_ENEMY_D
        & shoot_y < curr_y + HALF_ENEMY_D;
    assign alive = ps == S_ALIVE;
    assign spawned = ps != S_ALIVE & ns == S_ALIVE;
endmodule