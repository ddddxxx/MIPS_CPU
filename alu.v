module alu(x, y, op, result1, result2, equ);

    input [3:0] op;
    input [31:0] x, y;
    output [31:0] result1, result2;
    output equ;

    wire [63:0] mul;

    assign mul = x * y;

    assign result1 = (op==4'h0) ? x << y[4:0] : 32'hz,
           result1 = (op==4'h1) ? {{32{x[31]}}, x} >>> y[4:0] : 32'hz,
           result1 = (op==4'h2) ? x >> y[4:0] : 32'hz,
           result1 = (op==4'h3) ? mul[31:0] : 32'hz,
           result1 = (op==4'h4) ? x / y : 32'hz,
           result1 = (op==4'h5) ? x + y : 32'hz,
           result1 = (op==4'h6) ? x - y : 32'hz,
           result1 = (op==4'h7) ? x & y : 32'hz,
           result1 = (op==4'h8) ? x | y : 32'hz,
           result1 = (op==4'h9) ? x ^ y : 32'hz,
           result1 = (op==4'ha) ? x ~| y : 32'hz,
           result1 = (op==4'hb) ? $signed(x) < $signed(y) : 32'hz,
           result1 = (op==4'hc) ? x < y : 32'hz,
           result1 = (op>=4'hd) ? 32'h0 : 32'hz;

    assign result2 = (op==4'h3) ? mul[63:32] : 32'hz,
           result2 = (op==4'h4) ? x % y : 32'hz;

    assign equ = (x==y);

endmodule
