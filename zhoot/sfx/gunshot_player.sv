/* Plays the gunshot audio by outputting samples to the DAC
 *
 * Inputs:
 *   clk - 50MHz clock
 *   reset - global reset
 *   shot - user shot the gun this clock cycle
 *   aud_write_ready - DAC write ready signal
 *
 * Outputs:
 *   aud_write - assert high to write to DAC
 *   aud_write_d - sample to write to DAC
*/
module gunshot_player (
    input logic clk, reset,
    input logic shot,
    input logic aud_write_ready,
    output logic aud_write,
    output logic [23:0] aud_write_d
);
    localparam L = 47999;

    enum {S_IDLE, S_PLAYING} ps, ns;
    always_ff @(posedge clk)
        if (reset) ps <= S_IDLE;
        else ps <= ns;

    wire restart;
    wire [$clog2(L)-1:0] address;

    gunshot_rom gr (.clock(clk), .address, .q(aud_write_d));
    upctr #(.W($clog2(L)), .L(L)) ctr (.clk, .reset(shot), .inc(ps == S_PLAYING & aud_write), .cnt(address));

    // state transition
    always_comb
        case (ps)
            S_IDLE: ns = shot ? S_PLAYING : S_IDLE;
            S_PLAYING: ns = (address == L) ? S_IDLE : S_PLAYING;
        endcase
    
    assign aud_write = aud_write_ready;
endmodule