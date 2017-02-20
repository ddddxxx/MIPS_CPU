module TDM8 (clk, d7, d6, d5, d4, d3, d2, d1, d0, out, ctrl);

    input clk;
    input [7:0] d0, d1, d2, d3, d4, d5, d6, d7;
    output [7:0] out, ctrl;

    reg [7:0] ctrl = 8'b11111110;

    assign out = (d0&{8{~ctrl[0]}}) |
                 (d1&{8{~ctrl[1]}}) |
                 (d2&{8{~ctrl[2]}}) |
                 (d3&{8{~ctrl[3]}}) |
                 (d4&{8{~ctrl[4]}}) |
                 (d5&{8{~ctrl[5]}}) |
                 (d6&{8{~ctrl[6]}}) |
                 (d7&{8{~ctrl[7]}}) ;

    always @(posedge clk) begin
        ctrl <= {ctrl[6:0], ctrl[7]};
    end

endmodule
