import enemy_def::*;

module enemy (
    input logic clk, reset,
    // render coords
    input logic [9:0] x, shoot_x,
    input logic [8:0] y, shoot_y,
    input logic shot,
    // spawn inputs
    input logic spawn,
    // assumes write_x_d is in range
    input logic [9:0] write_x_d,
    // command enemy to move down
    input logic move,
    output logic [9:0] curr_x,
    output logic [8:0] curr_y,
    output logic render, killed
);
    localparam START_Y = 9'd48;
    localparam STEP_Y = 9'd10;
    localparam DYING_W = 25;
    localparam DYING_TICKS = 24_999_999;

    logic respawn;
    assign respawn = spawn & ps != S_ALIVE;

    enemy_state_t ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_DEAD;
        else ps <= ns;
    
    always_comb
        case (ps)
            S_DEAD: ns = respawn ? S_ALIVE : S_DEAD;
            S_ALIVE: ns = killed ? S_DYING : S_ALIVE;
            S_DYING: ns = dying_finished ? S_DEAD : S_DYING;
        endcase

    // center coordinate registers
    logic [9:0] x_ff;
    always_ff @(posedge clk)
        if (respawn) x_ff <= write_x_d;
        else x_ff <= x_ff;
    
    logic [8:0] y_ff;
    always_ff @(posedge clk)
        if (respawn) y_ff <= START_Y;
        else if (ps == S_ALIVE & move) y_ff <= y_ff + STEP_Y;
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
    enemy_render er (
        .clk, .x, .y,
        .state(ps), 
        .x_me(curr_x), .y_me(curr_y),
        .render
    );

    // outputs
    assign curr_x = x_ff;
    assign curr_y = y_ff;
    assign killed = ps == S_ALIVE & shot 
        & shoot_x >= curr_x - HALF_ENEMY_D
        & shoot_x < curr_x + HALF_ENEMY_D
        & shoot_y >= curr_y - HALF_ENEMY_D
        & shoot_y < curr_y + HALF_ENEMY_D;
endmodule