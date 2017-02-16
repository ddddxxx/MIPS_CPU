module alu_test();

    reg [3:0] op;
    reg [31:0] x, y;
    wire [31:0] result1, result2;

    alu test(x, y, op, result1, result2, equ);

    initial begin
        op = 4'b0;
        x = 32'b1;
        y = 32'b10;
        repeat (16) begin
            #10 op = op + 1;
        end
    end

    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(2, alu_test);
    end

endmodule
