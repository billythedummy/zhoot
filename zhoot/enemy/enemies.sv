module enemies #(parameter N_ENEMY=8) (
    input logic clk, reset,
    input logic [9:0] x, shoot_x,
    input logic [8:0] y, shoot_y,
    input logic shot,
    input logic gameover,
    output logic hit,
    output logic render,
    output logic [N_ENEMY-1 : 0] enemy_y
);

endmodule