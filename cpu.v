module cpu();

    // interrupt
    reg [2:0] interrupt_signs = 3'b0;   // io


    // clk
    reg clk_raw = 0;
    wire clk;

    assign clk = clk_raw & ~halt;

    initial begin
        repeat (1600) begin
            #10 clk_raw = 1;
            #10 clk_raw = 0;
        end
    end


    // pc
    wire [31:0] pc_in, pc_next, pc, pc4;
    register pc_modul(clk, pc_in, 1'b1, pc);

    assign pc4 = pc + 4;


    // instruction
    wire [9:0] inst_index;
    wire [31:0] instruction;
    wire [25:0] inst_addr;
    wire [15:0] inst_imm;
    wire [5:0] inst_op, inst_funct;
    wire [4:0] inst_rs, inst_rt, inst_rd, inst_shamt;

    rom rom_modul(inst_index, instruction);

    assign inst_index = pc[11:2];
    assign inst_addr = instruction[25:0];
    assign inst_imm = instruction[15:0];
    assign inst_op = instruction[31:26];
    assign inst_rs = instruction[25:21];
    assign inst_rt = instruction[20:16];
    assign inst_rd = instruction[15:11];
    assign inst_shamt = instruction[10:6];
    assign inst_funct = instruction[5:0];


    // ctrl
    wire [3:0] ctr_aluop;
    wire ctr_rf_dst, ctr_rf_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_branch_eq, ctr_branch_leq, ctr_jump_reg, ctr_jal, ctr_usign, ctr_shift_var, ctr_load_imm, ctr_store_half, ctr_exce_ret;

    controller ctrl_modul(inst_op, inst_funct, ctr_aluop, ctr_rf_dst, ctr_rf_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_branch_eq, ctr_branch_leq, ctr_jump_reg, ctr_jal, ctr_usign, ctr_sys, ctr_shift_var, ctr_load_imm, ctr_store_half, ctr_exce_ret);


    // regfile
    wire [4:0] rf_ar1, rf_ar2, rf_aw;
    wire [31:0] rf_dr1, rf_dr2, rf_dw;

    regfile regfile_modul(clk, rf_ar1, rf_ar2, rf_aw, ctr_rf_we, rf_dw, rf_dr1, rf_dr2);

    assign rf_ar1 = ctr_sys ? 32'h4 : inst_rs;
    assign rf_ar2 = ctr_sys ? 32'h2 : inst_rt;
    assign rf_aw = ctr_jal ? 32'h1f : ctr_rf_dst ? inst_rd : inst_rt;


    // alu
    wire [31:0] alu_x, alu_y, alu_r1, alu_r2, imm_extended;
    wire alu_eq, alu_leq;
    wire [31:0] shift_target;

    alu alu_modul(alu_x, alu_y, ctr_aluop, alu_r1, alu_r2, alu_eq, alu_leq);

    assign shift_target = ctr_shift_var ? rf_dr1 : {{27{inst_shamt[4]}}, inst_shamt};
    assign imm_extended = ctr_usign ? {16'b0, inst_imm} : {{16{inst_imm[15]}}, inst_imm};
    assign alu_x = ctr_shift ? rf_dr2 : rf_dr1;
    assign alu_y = ctr_shift ? shift_target : ctr_alu_src ? imm_extended : rf_dr2;


    // ram
    wire [31:0] ram_out;
    wire [31:0] ram_din;

    ram ram_modul(clk, alu_r1[11:2], ram_din, ctr_mem_we, ram_out);

    assign ram_din = ctr_store_half ? {ram_out[63:32], rf_dr2[31:0]} : rf_dr2;


    // sys
    wire [31:0] display;
    wire halt_enable;

    register display_reg(clk, rf_dr1, ctr_sys, display);
    register #(.width(1)) halt_reg(clk, 1'b1, halt_enable, halt);

    assign halt_enable = (ctr_sys && rf_dr2==32'ha);


    // cp0
    reg interrupt_disable = 1'b0;
    reg [2:0] interrupt_mask = 3'b0;
    wire [31:0] interrupt_entrance, epc;
    wire [2:0] interrupts;
    wire has_interrupt;

    register epc_reg(clk, pc_next, has_interrupt, epc);

    interrupt_driver interrupt_driver_modul(clk, interrupt_signs, interrupt_mask, interrupt_disable, interrupts);

    assign has_interrupt = |interrupts;

    assign interrupt_entrance = interrupts[2] ? 32'b0 // entrance 1
                              : interrupts[1] ? 32'b0 // entrance 2
                              : interrupts[0] ? 32'h36c // entrance 3
                              : 32'b0;

    always @(posedge clk) begin
        if (ctr_exce_ret) begin
            interrupt_disable <= 1'b0;
        end
        else if (has_interrupt) begin
            interrupt_disable <= 1'b1;
        end
    end


    // write back
    wire branch_fulfill;
    wire [31:0] branch_target;

    assign branch_fulfill = ctr_branch ? (ctr_branch_leq ? alu_leq : (alu_eq ~^ ctr_branch_eq)) : 0;
    assign branch_target = {{14{inst_imm[15]}}, {inst_imm}, 2'b0} + pc4;
    assign rf_dw = ctr_load_imm ? {{inst_imm}, 16'b0}
                 : ctr_jal ? pc4
                 : ctr_mem_to_reg ? ram_out
                 : alu_r1;
    assign pc_next = ctr_exce_ret ? epc
                   : ctr_jump_reg ? rf_dr1
                   : ctr_jump ? {pc4[31:28], inst_addr, 2'b0}
                   : branch_fulfill ? branch_target
                   : pc4;
    assign pc_in = has_interrupt ? interrupt_entrance : pc_next;


    // output
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(2, cpu);
    end


    // counter
    integer counter = 0;
    always @(posedge clk) begin
        counter <= counter + 1;
    end


    // test
    initial begin
        #20 interrupt_signs = 3'b1;
        #500 interrupt_signs = 3'b0;
        #1000 interrupt_signs = 3'b1;
        #20 interrupt_signs = 3'b0;
        #1000 interrupt_signs = 3'b1;
        #20 interrupt_signs = 3'b0;
    end


endmodule
