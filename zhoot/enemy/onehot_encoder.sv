/* Encodes unsigned to onehot
 * Note: 0 maps to 0..01
 *
 * Inputs:
 *   in - unsigned input
 *
 * Outputs:
 *   out - onehot output
*/
module onehot_encoder #(parameter IN_W=3) (
    input logic [IN_W-1:0] in,
    output logic [2**IN_W-1:0] out
);
    localparam OUT_W = 2**IN_W;

    logic [OUT_W-1:0] lut [0:OUT_W-1];
    
    genvar i;
    generate
        for (i = 0; i < OUT_W; i++) begin : gen_lut
            assign lut[i] = OUT_W'(1 << i);
        end
    endgenerate

    assign out = lut[in];
endmodule

module onehot_encoder_test ();
    localparam IN_W = 3;
    localparam OUT_W = 2 ** IN_W;

    logic [IN_W-1:0] in;
    logic [OUT_W-1:0] out;

    onehot_encoder #(.IN_W(IN_W)) dut (.*);

    integer i;
    initial begin
        for (i = 0; i < OUT_W; i++) begin
            in = IN_W'(i); #1; assert(out == OUT_W'(1 << i));
        end
        $stop;
    end
endmodule