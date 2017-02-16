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
    wire [4:0] inst_rs, inst_rt, inst_rd, inst_shamt, inst_mf;

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
    assign inst_mf = instruction[25:21];


    // ctrl
    wire [3:0] ctr_aluop;
    wire ctr_rf_dst, ctr_rf_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_branch_eq, ctr_branch_leq, ctr_jump_reg, ctr_jal, ctr_usign, ctr_shift_var, ctr_load_imm, ctr_store_half, ctr_exce_ret, ctr_mfc0, ctr_mtc0;

    controller ctrl_modul(inst_op, inst_funct, inst_mf, ctr_aluop, ctr_rf_dst, ctr_rf_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_branch_eq, ctr_branch_leq, ctr_jump_reg, ctr_jal, ctr_usign, ctr_sys, ctr_shift_var, ctr_load_imm, ctr_store_half, ctr_exce_ret, ctr_mfc0, ctr_mtc0);


    // regfile
    wire [4:0] rf_ar1, rf_ar2, rf_aw;
    wire [31:0] rf_dr1, rf_dr2, rf_dw;

    regfile regfile_modul(clk, rf_ar1, rf_ar2, rf_aw, ctr_rf_we, rf_dw, rf_dr1, rf_dr2);

    assign rf_ar1 = ctr_sys ? 32'h4 : inst_rs;
    assign rf_ar2 = ctr_sys ? 32'h2 : inst_rt;
    assign rf_aw = ctr_jal ? 32'h1f : ctr_rf_dst ? inst_rd : inst_rt;


    // alu
    wire [31:0] alu_x, alu_y, alu_r1, alu_r2, imm_extended;
    wire alu_eq;
    wire [31:0] shift_target;

    alu alu_modul(alu_x, alu_y, ctr_aluop, alu_r1, alu_r2, alu_eq);

    assign shift_target = ctr_shift_var ? rf_dr1 : {{27{inst_shamt[4]}}, inst_shamt};
    assign imm_extended = ctr_usign ? {16'b0, inst_imm} : {{16{inst_imm[15]}}, inst_imm};
    assign alu_x = ctr_shift ? rf_dr2 : rf_dr1;
    assign alu_y = ctr_shift ? shift_target : ctr_alu_src ? imm_extended : rf_dr2;


    // ram
    wire [31:0] ram_out;
    wire [31:0] ram_din;

    ram ram_modul(clk, alu_r1[11:2], ram_din, ctr_mem_we, ram_out);

    assign ram_din = ctr_store_half ? {ram_out[31:16], rf_dr2[15:0]} : rf_dr2;


    // sys
    wire [31:0] display;
    wire halt_enable;

    register display_reg(clk, rf_dr1, ctr_sys, display);
    register #(.width(1)) halt_reg(clk, 1'b1, halt_enable, halt);

    assign halt_enable = (ctr_sys && rf_dr2==32'ha);


    // cp0
    wire interrupt_disable, interrupt_disable_next;
    wire [2:0] interrupt_mask, interrupt_mask_next;
    wire [31:0] epc, epc_next;
    wire interrupt_disable_we, interrupt_mask_we, epc_we;
    wire [31:0] cp0_out;

    wire [31:0] interrupt_entrance;
    wire [2:0] interrupts;
    wire has_interrupt;

    interrupt_driver interrupt_driver_modul(clk, interrupt_signs, interrupt_mask, interrupt_disable, interrupts);

    // 0x16, 0o22, 0b10110
    register #(.width(1)) interrupt_disable_reg(clk, interrupt_disable_next, interrupt_disable_we, interrupt_disable);

    // 0x17, 0o23, 0b10111
    register #(.width(3)) interrupt_mask_reg(clk, interrupt_mask_next, interrupt_mask_we, interrupt_mask);

    // 0x0e, 0o14, 0b01110
    register epc_reg(clk, epc_next, epc_we, epc);

    assign has_interrupt = |interrupts;

    assign interrupt_entrance = interrupts[2] ? 32'b0 // entrance 1
                              : interrupts[1] ? 32'h600 // entrance 2
                              : interrupts[0] ? 32'h800 // entrance 3
                              : 32'b0;

    assign interrupt_disable_we = has_interrupt | ctr_exce_ret | (ctr_mtc0 && (inst_rd==5'h16));

    assign interrupt_disable_next = has_interrupt ? 1'b1
                                  : ctr_exce_ret ? 1'b0
                                  : rf_dr2;

    assign interrupt_mask_we = (ctr_mtc0 && (inst_rd==5'h17));

    assign interrupt_mask_next = rf_dr2;

    assign epc_we = has_interrupt | (ctr_mtc0 && (inst_rd==5'he));

    assign epc_next = has_interrupt ? pc_next : rf_dr2;

    assign cp0_out = (inst_rd==5'h16) ? {31'b0, interrupt_disable}
                   : (inst_rd==5'h17) ? {29'b0, interrupt_mask}
                   : (inst_rd==5'h0e) ? epc
                   : 32'b0;


    // write back
    wire rs_leq, branch_fulfill;
    wire [31:0] branch_target;

    assign rs_leq = ($signed(rf_dr1)<=$signed(0)) ? 1'b1 : 1'b0;
    assign branch_fulfill = ctr_branch ? (ctr_branch_leq ? rs_leq : (alu_eq ~^ ctr_branch_eq)) : 0;
    assign branch_target = {{14{inst_imm[15]}}, {inst_imm}, 2'b0} + pc4;
    assign rf_dw = ctr_mfc0 ? cp0_out
                 : ctr_load_imm ? {{inst_imm}, 16'b0}
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
        #1000 interrupt_signs = 3'b1;
        #700 interrupt_signs = 3'b10;
        #20 interrupt_signs = 3'b00;
        #100 interrupt_signs = 3'b10;
        #20 interrupt_signs = 3'b00;
    end


endmodule
