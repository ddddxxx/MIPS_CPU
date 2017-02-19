module cpu();

    // interrupt
    reg [2:0] interrupt_signs = 3'b0;   // io


    // clk
    reg clk_raw = 0;
    wire clk;

    assign clk = clk_raw & ~halt;

    initial begin
        repeat (2300) begin
            #2 clk_raw = 1;
            #2 clk_raw = 0;
        end
        // repeat (1600) begin
        //     #10 clk_raw = 1;
        //     #10 clk_raw = 0;
        // end
    end

    wire rst_ID, rst_EX, rst_MEM, rst_WB, pause_IF, pause_ID;

/* ================= IF ================= */

    wire [31:0] pc_in, pc_next, pc, pc4_IF;
    wire [9:0] inst_index;
    wire [31:0] instruction_IF;

    assign pc4_IF = pc + 4;
    assign inst_index = pc[11:2];

    assign pc_we = ~pause_IF;

    register pc_modul(clk, pc_in, pc_we, pc);

    rom rom_modul(inst_index, instruction_IF);

/* ================= IF ================= */

    reg [31:0] pc4_ID=0, instruction_ID=0;

    always @(posedge clk) begin
        if (~pause_ID) begin
            if (rst_ID) begin
                instruction_ID <= 32'b0;
                pc4_ID <= 32'b0;
            end
            else begin
                instruction_ID <= instruction_IF;
                pc4_ID <= pc4_IF;
            end
        end
    end

/* ================= ID ================= */

    wire [25:0] inst_addr_ID;
    wire [31:0] inst_imm_ID;
    wire [5:0] inst_op, inst_funct;
    wire [4:0] inst_rs, inst_rt_ID, inst_rd_ID, inst_shamt_ID, inst_mf;


    assign inst_addr_ID = instruction_ID[25:0];
    assign inst_imm_ID = {{16{instruction_ID[15]}}, instruction_ID[15:0]};
    assign inst_op = instruction_ID[31:26];
    assign inst_rs = instruction_ID[25:21];
    assign inst_rt_ID = instruction_ID[20:16];
    assign inst_rd_ID = instruction_ID[15:11];
    assign inst_shamt_ID = instruction_ID[10:6];
    assign inst_funct = instruction_ID[5:0];
    assign inst_mf = instruction_ID[25:21];


    wire [3:0] ctr_aluop_ID;
    wire ctr_rf_dst_ID, ctr_rf_we_ID, ctr_branch_ID, ctr_jump_ID, ctr_mem_we_ID, ctr_mem_to_reg_ID, ctr_alu_src_ID, ctr_shift_ID, ctr_branch_eq_ID, ctr_branch_leq_ID, ctr_jump_reg_ID, ctr_jal_ID, ctr_sys_ID, ctr_shift_var_ID, ctr_load_imm_ID, ctr_store_half_ID, ctr_exce_ret_ID, ctr_mfc0_ID, ctr_mtc0_ID;

    controller ctrl_modul(inst_op, inst_funct, inst_mf, ctr_aluop_ID, ctr_rf_dst_ID, ctr_rf_we_ID, ctr_branch_ID, ctr_jump_ID, ctr_mem_we_ID, ctr_mem_to_reg_ID, ctr_alu_src_ID, ctr_shift_ID, ctr_branch_eq_ID, ctr_branch_leq_ID, ctr_jump_reg_ID, ctr_jal_ID, ctr_sys_ID, ctr_shift_var_ID, ctr_load_imm_ID, ctr_store_half_ID, ctr_exce_ret_ID, ctr_mfc0_ID, ctr_mtc0_ID);


    wire [4:0] rf_ar1, rf_ar2, rf_aw_ID;
    wire [31:0] rf_dr1_raw, rf_dr2_raw, rf_dr1_ID, rf_dr2_ID, rf_dw_WB;

    reg [4:0] rf_aw_WB=0;
    reg ctr_rf_we_WB=0;

    regfile regfile_modul(clk, rf_ar1, rf_ar2, rf_aw_WB, ctr_rf_we_WB, rf_dw_WB, rf_dr1_raw, rf_dr2_raw);

    assign rf_ar1 = ctr_sys_ID ? 32'h4 : ctr_shift_ID ? inst_rt_ID : inst_rs;
    assign rf_ar2 = ctr_sys_ID ? 32'h2 : ctr_shift_ID ? inst_rs : inst_rt_ID;
    assign rf_aw_ID = ctr_jal_ID ? 5'h1f : ctr_rf_dst_ID ? inst_rd_ID : inst_rt_ID;

    // branch
    wire rs_leq, branch_fulfill;
    wire [31:0] branch_target;

    assign rs_leq = ($signed(rf_dr1_ID)<=$signed(0)) ? 1'b1 : 1'b0;
    assign rf_equ = (rf_dr1_ID==rf_dr2_ID);
    assign branch_fulfill = ctr_branch_ID ? (ctr_branch_leq_ID ? rs_leq : (rf_equ ~^ ctr_branch_eq_ID)) : 0;
    assign branch_target = {inst_imm_ID[29:0], 2'b0} + pc4_ID;
    assign pc_change = ctr_jump_reg_ID | ctr_jump_ID | branch_fulfill;
    assign pc_next = /* ctr_exce_ret_ID ? epc
                   : */ ctr_jump_reg_ID ? rf_dr1_ID
                   : ctr_jump_ID ? {pc4_ID[31:28], inst_addr_ID, 2'b0}
                   : branch_fulfill ? branch_target
                   : pc4_ID;

/* ================= ID ================= */

    reg [31:0] pc4_EX=0, rf_dr1_EX=0, rf_dr2_EX=0, inst_imm_EX=0;
    reg [4:0] inst_shamt_EX=0;
    reg [3:0] ctr_aluop_EX=0;
    reg ctr_rf_we_EX=0, ctr_mem_we_EX=0, ctr_mem_to_reg_EX=0, ctr_alu_src_EX=0, ctr_shift_EX=0, ctr_jal_EX=0, ctr_sys_EX=0, ctr_shift_var_EX=0, ctr_load_imm_EX=0, ctr_store_half_EX=0, ctr_exce_ret_EX=0, ctr_mfc0_EX=0, ctr_mtc0_EX=0;
    reg [4:0] rf_aw_EX=0;

    always @(posedge clk) begin
        if (rst_EX) begin
            pc4_EX <= 0;
            rf_dr1_EX <= 0;
            rf_dr2_EX <= 0;
            inst_imm_EX <= 0;
            inst_shamt_EX <= 0;
            ctr_aluop_EX <= 0;
            ctr_rf_we_EX <= 0;
            ctr_mem_we_EX <= 0;
            ctr_mem_to_reg_EX <= 0;
            ctr_alu_src_EX <= 0;
            ctr_shift_EX <= 0;
            ctr_jal_EX <= 0;
            ctr_sys_EX <= 0;
            ctr_shift_var_EX <= 0;
            ctr_load_imm_EX <= 0;
            ctr_store_half_EX <= 0;
            ctr_exce_ret_EX <= 0;
            ctr_mfc0_EX <= 0;
            ctr_mtc0_EX <= 0;
            rf_aw_EX <= 0;
        end
        else begin
            pc4_EX <= pc4_ID;
            rf_dr1_EX <= rf_dr1_ID;
            rf_dr2_EX <= rf_dr2_ID;
            inst_imm_EX <= inst_imm_ID;
            inst_shamt_EX <= inst_shamt_ID;
            ctr_aluop_EX <= ctr_aluop_ID;
            ctr_rf_we_EX <= ctr_rf_we_ID;
            ctr_mem_we_EX <= ctr_mem_we_ID;
            ctr_mem_to_reg_EX <= ctr_mem_to_reg_ID;
            ctr_alu_src_EX <= ctr_alu_src_ID;
            ctr_shift_EX <= ctr_shift_ID;
            ctr_jal_EX <= ctr_jal_ID;
            ctr_sys_EX <= ctr_sys_ID;
            ctr_shift_var_EX <= ctr_shift_var_ID;
            ctr_load_imm_EX <= ctr_load_imm_ID;
            ctr_store_half_EX <= ctr_store_half_ID;
            ctr_exce_ret_EX <= ctr_exce_ret_ID;
            ctr_mfc0_EX <= ctr_mfc0_ID;
            ctr_mtc0_EX <= ctr_mtc0_ID;
            rf_aw_EX <= rf_aw_ID;
        end
    end

/* ================= EX ================= */

    wire [31:0] alu_x, alu_y, alu_r1_EX, alu_r2_EX;
    wire alu_eq_EX;

    alu alu_modul(alu_x, alu_y, ctr_aluop_EX, alu_r1_EX, alu_r2_EX, alu_eq_EX);

    assign alu_x = rf_dr1_EX;
    assign alu_y = (ctr_shift_EX & ~ctr_shift_var_EX) ? {{27{inst_shamt_EX[4]}}, inst_shamt_EX}
                 : ctr_alu_src_EX ? inst_imm_EX
                 : rf_dr2_EX;

    // sys
    wire [31:0] display;
    wire halt_EX;

    register display_reg(clk, rf_dr1_EX, ctr_sys_EX, display);

    assign halt_EX = (ctr_sys_EX && rf_dr2_EX==32'ha);

    // redir
    wire rf_conflict_EX, rf_redir_target1_EX;
    wire [31:0] rf_redir_content_EX;

    assign rf_conflict_EX = ctr_rf_we_EX & |rf_aw_EX & ((rf_aw_EX==rf_ar1) | (rf_aw_EX==rf_ar2));
    assign rf_redir_target1_EX = (rf_aw_EX==rf_ar1);
    assign rf_redir_content_EX = ctr_load_imm_EX ? {{inst_imm_EX[15:0]}, 16'b0}
                               : ctr_jal_EX ? pc4_EX
                               : alu_r1_EX;

/* ================= EX ================= */

    reg [31:0] pc4_MEM=0, alu_r1_MEM=0, alu_r2_MEM=0, rf_dr2_MEM=0, inst_imm_MEM=0;
    reg ctr_rf_we_MEM=0, ctr_mem_we_MEM=0, ctr_mem_to_reg_MEM=0, ctr_alu_src_MEM=0, ctr_jal_MEM=0, ctr_load_imm_MEM=0, ctr_store_half_MEM=0, ctr_exce_ret_MEM=0, ctr_mfc0_MEM=0, ctr_mtc0_MEM=0;
    reg [4:0] rf_aw_MEM=0;
    reg halt_MEM=0;

    always @(posedge clk) begin
        if (rst_MEM) begin
            pc4_MEM <= 0;
            alu_r1_MEM <= 0;
            alu_r2_MEM <= 0;
            rf_dr2_MEM <= 0;
            inst_imm_MEM <= 0;
            ctr_rf_we_MEM <= 0;
            ctr_mem_we_MEM <= 0;
            ctr_mem_to_reg_MEM <= 0;
            ctr_alu_src_MEM <= 0;
            ctr_jal_MEM <= 0;
            ctr_load_imm_MEM <= 0;
            ctr_store_half_MEM <= 0;
            ctr_exce_ret_MEM <= 0;
            ctr_mfc0_MEM <= 0;
            ctr_mtc0_MEM <= 0;
            rf_aw_MEM <= 0;
            halt_MEM <= 0;
        end
        else begin
            pc4_MEM <= pc4_EX;
            alu_r1_MEM <= alu_r1_EX;
            alu_r2_MEM <= alu_r2_EX;
            rf_dr2_MEM <= rf_dr2_EX;
            inst_imm_MEM <= inst_imm_EX;
            ctr_rf_we_MEM <= ctr_rf_we_EX;
            ctr_mem_we_MEM <= ctr_mem_we_EX;
            ctr_mem_to_reg_MEM <= ctr_mem_to_reg_EX;
            ctr_alu_src_MEM <= ctr_alu_src_EX;
            ctr_jal_MEM <= ctr_jal_EX;
            ctr_load_imm_MEM <= ctr_load_imm_EX;
            ctr_store_half_MEM <= ctr_store_half_EX;
            ctr_exce_ret_MEM <= ctr_exce_ret_EX;
            ctr_mfc0_MEM <= ctr_mfc0_EX;
            ctr_mtc0_MEM <= ctr_mtc0_EX;
            rf_aw_MEM <= rf_aw_EX;
            halt_MEM <= halt_EX;
        end
    end

/* ================= MEM ================ */

    wire [31:0] ram_out_MEM;
    wire [31:0] ram_din;

    ram ram_modul(clk, alu_r1_MEM[11:2], ram_din, ctr_mem_we_MEM, ram_out_MEM);

    assign ram_din = ctr_store_half_MEM ? {ram_out_MEM[31:16], rf_dr2_MEM[15:0]} : rf_dr2_MEM;

    // redir
    wire rf_conflict_MEM, rf_redir_target1_MEM;
    wire [31:0] rf_redir_content_MEM;

    assign rf_conflict_MEM = ctr_rf_we_MEM & |rf_aw_MEM & ((rf_aw_MEM==rf_ar1) | (rf_aw_MEM==rf_ar2));
    assign rf_redir_target1_MEM = (rf_aw_MEM==rf_ar1);
    assign rf_redir_content_MEM = ctr_load_imm_MEM ? {{inst_imm_MEM[15:0]}, 16'b0}
                                : ctr_jal_MEM ? pc4_MEM
                                : alu_r1_MEM;

/* ================= MEM ================ */

    reg [31:0] pc4_WB=0, alu_r1_WB=0, inst_imm_WB=0, ram_out_WB=0;
    reg ctr_mfc0_WB=0, ctr_load_imm_WB=0, ctr_jal_WB=0, ctr_mem_to_reg_WB=0;
    reg halt_WB=0;

    always @(posedge clk) begin
        if (rst_WB) begin
            pc4_WB <= 0;
            alu_r1_WB <= 0;
            inst_imm_WB <= 0;
            ram_out_WB <= 0;
            ctr_rf_we_WB <= 0;
            ctr_mfc0_WB <= 0;
            ctr_load_imm_WB <= 0;
            ctr_jal_WB <= 0;
            ctr_mem_to_reg_WB <= 0;
            rf_aw_WB <= 0;
            halt_WB <= 0;
        end
        else begin
            pc4_WB <= pc4_MEM;
            alu_r1_WB <= alu_r1_MEM;
            inst_imm_WB <= inst_imm_MEM;
            ram_out_WB <= ram_out_MEM;
            ctr_rf_we_WB <= ctr_rf_we_MEM;
            ctr_mfc0_WB <= ctr_mfc0_MEM;
            ctr_load_imm_WB <= ctr_load_imm_MEM;
            ctr_jal_WB <= ctr_jal_MEM;
            ctr_mem_to_reg_WB <= ctr_mem_to_reg_MEM;
            rf_aw_WB <= rf_aw_MEM;
            halt_WB <= halt_MEM;
        end
    end

/* ================= WB ================= */

    assign rf_dw_WB = /* ctr_mfc0_WB ? cp0_out
                    : */ctr_load_imm_WB ? {{inst_imm_WB}, 16'b0}
                    : ctr_jal_WB ? pc4_WB
                    : ctr_mem_to_reg_WB ? ram_out_WB
                    : alu_r1_WB;

    register #(.width(1)) halt_reg(clk, 1'b1, halt_WB, halt);

    // redir
    wire rf_conflict_WB, rf_redir_target1_WB;

    assign rf_conflict_WB = ctr_rf_we_WB & |rf_aw_WB & ((rf_aw_WB==rf_ar1) | (rf_aw_WB==rf_ar2));
    assign rf_redir_target1_WB = (rf_aw_WB==rf_ar1);

/* ================= WB ================= */

    wire conflict_load_use, conflict_redirable;

    assign pc_in = pc_change ? pc_next : pc4_IF;
    assign rst_ID = pc_change;

    assign conflict_load_use = (rf_conflict_EX & ctr_mem_to_reg_EX) | (rf_conflict_MEM & ctr_mem_to_reg_MEM);
    assign pause_IF = conflict_load_use;
    assign rst_EX = conflict_load_use;
    assign pause_ID = conflict_load_use;

    assign rf_dr1_ID = (rf_conflict_EX & ~ctr_mem_to_reg_EX & rf_redir_target1_EX) ? rf_redir_content_EX
                     : (rf_conflict_MEM & ~ctr_mem_to_reg_MEM & rf_redir_target1_MEM) ? rf_redir_content_MEM
                     : (rf_conflict_WB & rf_redir_target1_WB) ? rf_dw_WB
                     : rf_dr1_raw;
    assign rf_dr2_ID = (rf_conflict_EX & ~ctr_mem_to_reg_EX & ~rf_redir_target1_EX) ? rf_redir_content_EX
                     : (rf_conflict_MEM & ~ctr_mem_to_reg_MEM & ~rf_redir_target1_MEM) ? rf_redir_content_MEM
                     : (rf_conflict_WB & ~rf_redir_target1_WB) ? rf_dw_WB
                     : rf_dr2_raw;


/*
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
*/

    // output
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(2, cpu);
    end


    // counter
    integer clk_cnt = 0;
    always @(posedge clk) begin
        clk_cnt <= clk_cnt + 1;
    end

    integer conflict_cnt = 0;
    always @(posedge clk) begin
        if (conflict_load_use) begin
            conflict_cnt = conflict_cnt + 1;
        end
    end


    // test interrupt
    // initial begin
    //     #1000 interrupt_signs = 3'b1;
    //     #700 interrupt_signs = 3'b10;
    //     #20 interrupt_signs = 3'b00;
    //     #100 interrupt_signs = 3'b10;
    //     #20 interrupt_signs = 3'b00;
    // end


endmodule
