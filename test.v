module test();

    reg [31:0] t = 32'h80000000;

    initial begin
        $display("%d", $signed(t)>>1);
    end

endmodule
