module encoder4_7 (in, out);

    input [3:0] in;
    output [7:0] out;

    assign out = (in==4'h0) ? 8'b11000000 : 8'hz,
           out = (in==4'h1) ? 8'b11111001 : 8'hz,
           out = (in==4'h2) ? 8'b10100100 : 8'hz,
           out = (in==4'h3) ? 8'b10110000 : 8'hz,
           out = (in==4'h4) ? 8'b10011001 : 8'hz,
           out = (in==4'h5) ? 8'b10010010 : 8'hz,
           out = (in==4'h6) ? 8'b10000010 : 8'hz,
           out = (in==4'h7) ? 8'b11111000 : 8'hz,
           out = (in==4'h8) ? 8'b10000000 : 8'hz,
           out = (in==4'h9) ? 8'b10010000 : 8'hz,
           out = (in==4'ha) ? 8'b10001000 : 8'hz,
           out = (in==4'hb) ? 8'b10000011 : 8'hz,
           out = (in==4'hc) ? 8'b11000110 : 8'hz,
           out = (in==4'hd) ? 8'b10100001 : 8'hz,
           out = (in==4'he) ? 8'b10000110 : 8'hz,
           out = (in==4'hf) ? 8'b10001110 : 8'hz;

endmodule
