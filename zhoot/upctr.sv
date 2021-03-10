// wrapping up counter with increment and reset signal and custom max L
module upctr #(parameter W=3, L=2**W - 1) (
    input wire clk, reset,
    input wire inc,
    output reg [W-1:0] cnt
);

    always_ff @(posedge clk)
        if (reset) cnt <= W'(0);
        else if (inc)
            if (cnt == W'(L)) cnt <= W'(0);
            else cnt <= cnt + W'(1);

endmodule