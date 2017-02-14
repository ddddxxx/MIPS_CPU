module falling_edge_register (clk, din, WE, dout);

    parameter width = 32;

    input clk, WE;
    input [width-1:0] din;
    output [width-1:0] dout;

    reg [width-1:0] dout = 0;

    always @(negedge clk) begin
        if (WE) begin
            dout <= din;
        end
    end

endmodule
