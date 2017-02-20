module even_divider (in, out);

    parameter frequency = 10;

    input in;
    output out;

    reg out = 0;
    reg [31:0] count = 0;

    assign halfCycle = (count==frequency/2-1);

    always @(posedge in) begin
        out <= out ^ halfCycle;
        count <= ~{32{halfCycle}} & (count+1);
    end

endmodule
