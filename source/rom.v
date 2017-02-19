module rom(addr, data);

    input [9:0] addr;
    output [31:0] data;

    reg [31:0] mem[0:1023];

    assign data = mem[addr];

    initial begin
        // $readmemh("utopian_pipeline.txt", mem, 0, 16);
        $readmemh("benchmark.txt", mem, 0, 218);
        $readmemh("ISR2.txt", mem, 'h180, 'h1ab);
        $readmemh("ISR3.txt", mem, 'h200, 'h227);
    end

endmodule
