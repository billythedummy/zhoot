/* "Random" generator of starting x-coordinates of enemies
 * Really just a hardcoded array of random-looking cycling x-coordinates
 * that is somewhat evenly distributed across the width of the screen
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - resets this module
 *   next - 1 to cycle to next x-coordinate
 *
 * Outputs:
 *   x - current x-coordinate in the cycle that is outputted
*/
module enemy_x_gen (
    input logic clk, reset, next,
    output logic [9:0] x
);
    localparam LOG_N = 3;

    logic [LOG_N-1:0] addr;
    upctr #(.W(LOG_N)) ctr (.clk, .reset, .inc(next), .cnt(addr));

    logic [9:0] rom [0:2**LOG_N-1];

    assign x = rom[addr];

    initial begin
        rom[0] = 10'(99);
        rom[1] = 10'(257);
        rom[2] = 10'(170);
        rom[3] = 10'(400);
        rom[4] = 10'(33);
        rom[5] = 10'(523);
        rom[6] = 10'(320);
        rom[7] = 10'(603);
    end
endmodule