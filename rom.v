module rom(addr, data);

    input [9:0] addr;
    output [31:0] data;

    reg [31:0] mem[0:1023];

    assign data = mem[addr];

    initial begin
        // $readmemh("benchmark.txt", mem, 0, 218);
        $readmemh("bmz.txt", mem, 0, 227);
    end

endmodule
