module controller(op, funct, mf, aluop, reg_dst, reg_WE, branch, jump, mem_WE, mem_to_reg, imm_op, branch_eq, branch_leq, jump_reg, jal, sys, shift_imm, load_upper_imm, store_half, exce_ret, mfc0, mtc0);

    input [5:0] op, funct;
    input [4:0] mf;
    output [3:0] aluop;
    output reg_dst, reg_WE, branch, jump, mem_WE, mem_to_reg, imm_op, branch_eq, branch_leq, jump_reg, jal, sys, shift_imm, load_upper_imm, store_half, exce_ret, mfc0, mtc0;

    assign reg_dst = (op==6'b000000) ? 4'b1 : 4'b0;

    assign reg_WE = ~((op==6'b101011) ||
                      (op==6'b101001) ||
                      (op==6'b000100) ||
                      (op==6'b000101) ||
                      (op==6'b000010) ||
                      ((op==6'b010000) && ((funct==6'b011000) || (mf==5'b00100))) ||  // ERET, mtc0
                      ((op==6'b000000) && ((funct==6'b001000) || (funct==6'b001100))));

    assign aluop = ((op==6'b001000) ||
                    (op==6'b001001) ||
                    ((op==6'b000000) && ((funct==6'b100000) || (funct==6'b100001)))) ? 4'b0101 : 4'bz,  // Add
           aluop = ((op==6'b001100) ||
                    ((op==6'b000000) && (funct==6'b100100))) ? 4'b0111 : 4'bz,  // And
           aluop = ((op==6'b000000) && (funct==6'b000000)) ? 4'b0000: 4'bz,     // Shift Left Logical
           aluop = ((op==6'b000000) && (funct==6'b000011)) ? 4'b0001: 4'bz,     // Shift Right Arithmetic
           aluop = ((op==6'b000000) && (funct==6'b000010)) ? 4'b0010: 4'bz,     // Shift Right Arithmetic
           aluop = ((op==6'b000000) && (funct==6'b100010)) ? 4'b0110: 4'bz,     // Sub
           aluop = ((op==6'b001101) ||
                    ((op==6'b000000) && (funct==6'b100101))) ? 4'b1000 : 4'bz,  // Or
           aluop = ((op==6'b000000) && (funct==6'b100111)) ? 4'b1010 : 4'bz,    // Nor
           aluop = ((op==6'b100011) ||
                    (op==6'b101011) ||
                    (op==6'b101001)) ? 4'b0101 : 4'bz, // Load / Store Word, sh
           aluop = ((op==6'b001010) ||
                    ((op==6'b000000) && (funct==6'b101010))) ? 4'b1011 : 4'bz,  // Set Less Than
           aluop = ((op==6'b000000) && (funct==6'b101011)) ? 4'b1100: 4'bz,     // Set Less Than Unsigned
           aluop = ((op==6'b000000) && (funct==6'b000110)) ? 4'b0010: 4'bz,     // SRLV

           aluop = ((op==6'b000010) || (op==6'b000011)) ? 4'b0101 : 4'bz, // fill
           aluop = ((op==6'b000000) && ((funct==6'b001000) || (funct==6'b001100))) ? 4'b0101 : 4'bz;  // fill

    assign branch = ((op[5:1]==5'b00010) || (op==6'b000110)) ? 4'b1 : 4'b0;

    assign jump = (op[5:1]==5'b00001) ? 4'b1 : 4'b0;

    assign mem_WE = ((op==6'b101011) || (op==6'b101001)) ? 4'b1 : 4'b0; // sw, sh

    assign mem_to_reg = (op==6'b100011) ? 4'b1 : 4'b0;

    assign imm_op = ((op!=6'b000000) && (op[5:1]!=5'b00010)) ? 4'b1 : 4'b0;

    assign branch_eq = (op==6'b000100) ? 4'b1 : 4'b0;

    assign branch_leq = (op==6'b000110) ? 4'b1 : 4'b0;

    assign jump_reg = ((op==6'b000000) && (funct==6'b001000)) ? 4'b1 : 4'b0;

    assign jal = (op==6'b000011) ? 4'b1 : 4'b0;

    assign sys = ((op==6'b000000) && (funct==6'b001100)) ? 4'b1 : 4'b0;

    assign shift_imm = ((op==6'b000000) && ((funct==6'b000000) || (funct[5:1]==5'b00001))) ? 4'b1 : 4'b0;

    assign load_upper_imm = (op==6'b001111) ? 4'b1 : 4'b0;

    assign store_half = (op==6'b101001) ? 4'b1 : 4'b0;

    assign exce_ret = ((op==6'b010000) && (funct==6'b011000) && (mf[4])) ? 4'b1 : 4'b0;

    assign mfc0 = ((op==6'b010000) && (mf==5'b00000)) ? 4'b1 : 4'b0;

    assign mtc0 = ((op==6'b010000) && (mf==5'b00100)) ? 4'b1 : 4'b0;

endmodule
