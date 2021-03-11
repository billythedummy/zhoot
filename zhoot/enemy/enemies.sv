module enemies #(parameter N_ENEMY=8) (
    input logic clk, reset, start,
    input logic [9:0] x, shoot_x,
    input logic [8:0] y, shoot_y,
    input logic shot,
    input logic gameover,
    output logic killed,
    output logic render,
    output logic [N_ENEMY-1:0] enemy_alive,
    output logic [8:0] enemy_y [N_ENEMY-1:0]
);
    localparam LOG_N_ENEMY = $clog2(N_ENEMY);
    // cooldown between new enemies spawning
    localparam RESPAWN_TICKS = 9_999_999;
    localparam LOG_RESPAWN_TICKS = $clog2(RESPAWN_TICKS);

    logic begin_reset;
    assign begin_reset = ps == S_OVER & ns == S_RESETTING;
    logic starting_game;
    assign starting_game = ps == S_RESETTING & ns == S_GAME;

    // FSM
    enum {S_OVER, S_RESETTING, S_GAME} ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_OVER;
        else ps <= ns;
    always_comb
        case (ps)
            S_OVER: ns = start ? S_RESETTING : S_OVER;
            S_RESETTING: ns = addr_fifo_full ? S_GAME : S_RESETTING;
            S_GAME: ns = gameover ? S_OVER : S_GAME;
        endcase

    // enemies array
    logic should_spawn;
    assign should_spawn = ps == S_GAME & ~addr_fifo_empty & respawn_time_up;
    logic [N_ENEMY-1:0] spawn;
    assign spawn = should_spawn ? addr_fifo_r_data : N_ENEMY'(0);
    logic [9:0] write_x_d;
    logic move;
    assign move = ps == S_GAME ? move_always : 1'b0;
    logic shot_valid;
    assign shot_valid = shot & ps == S_GAME;
    logic [N_ENEMY-1:0] render_all;
    logic [N_ENEMY-1:0] killed_all;
    logic [N_ENEMY-1:0] spawned_all;
    logic [N_ENEMY-1:0] shot_blocked_all;
    // first enemy highest shot priority
    assign shot_blocked_all[0] = 1'b0;
    enemy enemy_0 (
        .clk, .reset(begin_reset),
        .x, .y,
        .shoot_x, .shoot_y, .shot(shot_valid), .shot_blocked(shot_blocked_all[0]),
        .spawn(spawn[0]),
        .write_x_d,
        .move,
        .curr_y(enemy_y[0]),
        .render(render_all[0]),
        .killed(killed_all[0]),
        .alive(enemy_alive[0]),
        .spawned(spawned_all[0])
    );
    // resolving shot overlapping pixels: 
    // enemies are only killed if no enemy with lower index than it was also killed 
    genvar i;
    generate
        for (i = 1; i < N_ENEMY; i++) begin : gen_enemies
            assign shot_blocked_all[i] = |killed_all[i-1:0];
            enemy enemy_i (
                .clk, .reset(begin_reset),
                .x, .y,
                .shoot_x, .shoot_y, .shot(shot_valid), .shot_blocked(shot_blocked_all[i]),
                .spawn(spawn[i]),
                .write_x_d,
                .move,
                .curr_y(enemy_y[i]),
                .render(render_all[i]),
                .killed(killed_all[i]),
                .alive(enemy_alive[i]),
                .spawned(spawned_all[i])
            );
        end
    endgenerate


    enemy_x_gen emx (.clk, .reset(starting_game), .next(spawned | shot), .x(write_x_d));

    logic move_always;
    enemy_move_ctrl emc (.clk, .reset(starting_game), .move(move_always));

    // upctr for cooldown between enemies spawning
    logic [LOG_RESPAWN_TICKS-1:0] respawn_ticks;
    logic respawn_time_up;
    assign respawn_time_up = respawn_ticks == RESPAWN_TICKS;
    logic respawn_running;
    assign respawn_running = ~respawn_time_up & respawn_ticks != 0;
    upctr #(.W(LOG_RESPAWN_TICKS), .L(RESPAWN_TICKS)) re_ctr (
        .clk, .reset(~respawn_running & (spawned | killed)),
        .inc(~respawn_time_up), .cnt(respawn_ticks)
    );


    // upctr for resetting enemy addresses
    logic [LOG_N_ENEMY-1:0] addr_reset;
    upctr #(.W(LOG_N_ENEMY), .L(N_ENEMY-1)) addr_reset_ctr (
        .clk, .reset(begin_reset),
        .inc(ps == S_RESETTING), .cnt(addr_reset)
    );
    logic [N_ENEMY-1:0] addr_reset_onehot;
    onehot_encoder #(.IN_W(LOG_N_ENEMY)) reset_oh (.in(addr_reset), .out(addr_reset_onehot));

    // Address fifo, stores onehot-encoded enemy spawn index
    logic [N_ENEMY-1:0] addr_fifo_w_data, addr_fifo_r_data;
    logic addr_fifo_empty, addr_fifo_full;
    assign addr_fifo_w_data = ps == S_RESETTING ? addr_reset_onehot : killed_all;
    // only dequeue when successfully spawned enemy
    logic spawned;
    assign spawned = |spawned_all;
    fifo #(.DATA_WIDTH(N_ENEMY), .ADDR_WIDTH(LOG_N_ENEMY)) addr_fifo (
        .clk, .reset(begin_reset),
        .rd(spawned), .wr(ps == S_RESETTING | (ps == S_GAME & killed)),
        .empty(addr_fifo_empty), .full(addr_fifo_full),
        .w_data(addr_fifo_w_data),
        .r_data(addr_fifo_r_data)
    );

    // output assignments
    assign render = |render_all;
    assign killed = |killed_all;
endmodule