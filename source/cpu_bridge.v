`timescale 100us / 10us
`define TEST 1

module cpu_bridge(clk_in, interrupt_signs_in, display_src, display_seg, display_ctrl);

    input clk_in;
    input [2:0] interrupt_signs_in, display_src;
    output[7:0] display_seg, display_ctrl;

    `ifndef TEST
        wire clk;
        even_divider #(.frequency(100000)) divide1KHz(clk_in, clk);
        wire [2:0] interrupt_signs;
        assign interrupt_signs = interrupt_signs_in;
    `else
        reg clk=0;
        initial begin
            repeat (2300) begin
                #5 clk= 1;
                #5 clk = 0;
            end
        end
        reg [2:0] interrupt_signs=0;
        initial begin
            #2000 interrupt_signs = 3'b1;
            #500 interrupt_signs = 3'b10;
            #50 interrupt_signs = 3'b00;
            #200 interrupt_signs = 3'b11;
            #50 interrupt_signs = 3'b00;
        end
        initial begin
            $dumpfile("cpu_bridge.vcd");
            $dumpvars(3, cpu_bridge);
        end
    `endif

    wire [31:0] display, clk_cnt, conflict_cnt, jump_cnt, branch_succeed_cnt, branch_fail_cnt;
    cpu cpu(clk, interrupt_signs, display, clk_cnt, conflict_cnt, jump_cnt, branch_succeed_cnt, branch_fail_cnt);

    wire [31:0] display_content;
    assign display_content = (display_src==3'h0) ? display : 32'hz,
           display_content = (display_src==3'h1) ? clk_cnt : 32'hz,
           display_content = (display_src==3'h2) ? conflict_cnt : 32'hz,
           display_content = (display_src==3'h3) ? jump_cnt : 32'hz,
           display_content = (display_src==3'h4) ? branch_succeed_cnt : 32'hz,
           display_content = (display_src==3'h5) ? branch_fail_cnt : 32'hz;

    wire [7:0] n7, n6, n5, n4, n3, n2, n1, n0;
    encoder4_7
        encode0(display_content[3:0], n0),
        encode1(display_content[7:4], n1),
        encode2(display_content[11:8], n2),
        encode3(display_content[15:12], n3),
        encode4(display_content[19:16], n4),
        encode5(display_content[23:20], n5),
        encode6(display_content[27:24], n6),
        encode7(display_content[31:28], n7);

    TDM8
        TDM(clk, n7, n6, n5, n4, n3, n2, n1, n0, display_seg, display_ctrl);

endmodule
