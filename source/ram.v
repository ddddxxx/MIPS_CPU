module ram(clk, addr, din, WE, dout);

    input clk, WE;
    input [9:0] addr;
    input [31:0] din;
    output [31:0] dout;

    reg [31:0] mem[0:1023];

    assign dout = mem[addr];

    always @(posedge clk) begin
        if (WE) begin
            mem[addr] <= din;
        end
    end

    integer i;
    initial begin
        for (i=0; i<1024; i=i+1) begin
            mem[i] = 0;
        end
    end

endmodule
