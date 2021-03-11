module gamestate #(parameter N_ENEMY=8) (
    input logic clk, reset, start,
    input logic [9:0] x,
    input logic [8:0] y,
    input logic [N_ENEMY-1:0] enemy_alive,
    input logic [8:0] enemy_y [N_ENEMY-1:0],
    output logic gameover,
    output logic render
);
    localparam Y_THRESHOLD = 9'd448;

    // FSM
    enum {S_OVER, S_GAME} ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_OVER;
        else ps <= ns;
    always_comb
        case (ps)
            S_OVER: ns = start ? S_GAME : S_OVER;
            S_GAME: ns = gameover ? S_OVER : S_GAME;
        endcase

    // render
    logic render_gameover;
    gameover_render gr (.clk, .x, .y, .render(render_gameover));
    assign render = ps == S_OVER ? render_gameover : 1'b0;

    // check if enemy has passed bottom of screen
    logic [N_ENEMY-1:0] enemy_passed;
    genvar i;
    generate
        for (i = 0; i < N_ENEMY; i++) begin : gen_cmp
            assign enemy_passed[i] = enemy_y[i] > Y_THRESHOLD;
        end
    endgenerate
    assign gameover = |(enemy_alive & enemy_passed);
endmodule