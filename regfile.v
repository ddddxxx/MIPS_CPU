module regfile(clk, a1, a2, aw, WE, din, r1, r2);

    input clk, WE;
    input [4:0] a1, a2, aw;
    input [31:0] din;
    output [31:0] r1, r2;

    reg [31:0] regs[0:31];

    assign r1 = |a1 ? regs[a1] : 0;
    assign r2 = |a2 ? regs[a2] : 0;

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

    //debug
    wire [31:0] sp, s0, s1, t0, t1, a0, v0;

    assign sp = regs[29];
    assign s0 = regs[16];
    assign s1 = regs[17];
    assign t0 = regs[8];
    assign t1 = regs[9];
    assign a0 = regs[4];
    assign v0 = regs[2];

endmodule
