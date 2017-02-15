module cpu();

    // clk
    reg clk = 1;

    initial begin
        repeat (1600) begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end

    // pc
    wire [31:0] pc_in, pc, pc4;
    falling_edge_register pc_modul(clk, pc_in, ~halt, pc);

    assign pc4 = pc + 4;


    // instruction
    wire [9:0] rom_addr;
    wire [31:0] instruction;
    wire [25:0] inst_addr;
    wire [15:0] inst_imm;
    wire [5:0] inst_op, inst_funct;
    wire [4:0] inst_rs, inst_rt, inst_rd, inst_shamt;

    rom rom_modul(rom_addr, instruction);

    assign rom_addr = pc[11:2];
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
    wire ctr_reg_dst, ctr_reg_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_equ, ctr_jump_reg, ctr_jal, ctr_usign, ctr_shift_var, ctr_load_imm, ctr_store_half;

    controller ctrl_modul(inst_op, inst_funct, ctr_aluop, ctr_reg_dst, ctr_reg_we, ctr_branch, ctr_jump, ctr_mem_we, ctr_mem_to_reg, ctr_alu_src, ctr_shift, ctr_equ, ctr_jump_reg, ctr_jal, ctr_usign, ctr_sys, ctr_shift_var, ctr_load_imm, ctr_store_half);


    // regfile
    wire [4:0] rf_ar1, rf_ar2, rf_aw;
    wire [31:0] rf_dr1, rf_dr2, rf_dw;

    regfile regfile_modul(clk, rf_ar1, rf_ar2, rf_aw, ctr_reg_we, rf_dw, rf_dr1, rf_dr2);

    assign rf_ar1 = ctr_sys ? 32'h4 : inst_rs;
    assign rf_ar2 = ctr_sys ? 32'h2 : inst_rt;
    assign rf_aw = ctr_jal ? 32'h1f : ctr_reg_dst ? inst_rd : inst_rt;


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

    assign ram_din = ctr_store_half ? {ram_out[63:32], rf_dr2[31:0]} : rf_dr2;

    // write back
    wire [31:0] branch_target;

    assign branch_fulfill = ctr_branch ? (alu_eq ~^ ctr_equ) : 0;
    assign branch_target = {{14{inst_imm[15]}}, {inst_imm}, 2'b0} + pc4;
    assign rf_dw = ctr_load_imm ? {{inst_imm}, 16'b0} : ctr_jal ? pc4 : ctr_mem_to_reg ? ram_out : alu_r1;
    assign pc_in = ctr_jump_reg ? rf_dr1 : ctr_jump ? {pc4[31:28], inst_addr, 2'b0} : branch_fulfill ? branch_target : pc4;

    // sys
    wire [31:0] display;
    wire halt_enable;

    register display_reg(clk, rf_dr1, ctr_sys, display);
    register #(.width(1)) halt_reg(clk, 1'b1, halt_enable, halt);

    assign halt_enable = (ctr_sys && rf_dr2==32'ha);

    // output
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(2, cpu);
    end

endmodule
