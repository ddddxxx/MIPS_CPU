module regfile(clk, a1, a2, aw, WE, din, r1, r2);

    input clk, WE;
    input [4:0] a1, a2, aw;
    input [31:0] din;
    output [31:0] r1, r2;

    reg [31:0] regs[0:31];

    assign r1 = regs[a1];
    assign r2 = regs[a2];

    always @(posedge clk) begin
        if (WE) begin
            regs[aw] <= din;
        end
    end

    integer i;
    initial begin
        for (i=0; i<32; i=i+1) begin
            regs[i] = 0;
        end
    end

endmodule
