module interrupt_driver(clk, interrupt_async, interrupt_mask, interrupt_disable, interrupt_sign_out);

    input clk;
    input [2:0] interrupt_async, interrupt_mask;
    input interrupt_disable;
    output [2:0] interrupt_sign_out;


    // sync and detect
    reg [2:0] interrupt_sync_old, interrupt_sync;
    wire [2:0] interrupt_detected;

    always @(posedge clk) begin
        interrupt_sync <= interrupt_sync_old;
        interrupt_sync_old <= interrupt_async;
    end

    assign interrupt_detected = interrupt_sync_old & ~interrupt_sync;


    // store
    reg interrupt_reg1 = 1'b0, interrupt_reg2 = 1'b0, interrupt_reg3 = 1'b0;
    wire interrupt_sign1, interrupt_sign2, interrupt_sign3;

    assign interrupt_sign1 = interrupt_detected[2];
    assign interrupt_sign2 = interrupt_detected[1];
    assign interrupt_sign3 = interrupt_detected[0];

    always @(posedge clk) begin
        if (interrupt_detected[2]) begin
            interrupt_reg1 <= 1;
        end else if (interrupt_sign_out1) begin
            interrupt_reg1 <= 0;
        end

        if (interrupt_detected[1]) begin
            interrupt_reg2 <= 1;
        end else if (interrupt_sign_out2) begin
            interrupt_reg2 <= 0;
        end

        if (interrupt_detected[0]) begin
            interrupt_reg3 <= 1;
        end else if (interrupt_sign_out3) begin
            interrupt_reg3 <= 0;
        end
    end


    // arbitration
    assign interrupt_sign_out1 = ~interrupt_disable & ~interrupt_mask[2] & interrupt_reg1;
    assign interrupt_sign_out2 = ~interrupt_sign_out1 & ~interrupt_disable & ~interrupt_mask[1] & interrupt_reg2;
    assign interrupt_sign_out3 = ~interrupt_sign_out1 & ~interrupt_sign_out2 & ~interrupt_disable & ~interrupt_mask[0] & interrupt_reg3;

    assign interrupt_sign_out = {interrupt_sign_out1, interrupt_sign_out2, interrupt_sign_out3};

endmodule
