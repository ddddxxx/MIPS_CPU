.text
# push regs
addi $sp, $sp, 4
sw $s0, ($sp)
addi $sp, $sp, 4
sw $s1, ($sp)
addi $sp, $sp, 4
sw $t0, ($sp)
addi $sp, $sp, 4
sw $t1, ($sp)
addi $sp, $sp, 4
sw $a0, ($sp)
addi $sp, $sp, 4
sw $v0, ($sp)

# save cp0
mfc0 $s0, $23
mfc0 $s1, $14

# interrupt mask
addi $t0, $zero, 3
mtc0 $t0, $23

# enable interrupt
mtc0 $zero, $22

addi $v0, $zero, 34
addi $a0, $zero, 0x1000
syscall
addi $a0, $zero, 0x100
syscall
addi $a0, $zero, 0x10
syscall
addi $a0, $zero, 0x1
syscall

# disable interrupt
addi $t1, $zero, 0x1
mtc0 $t1, $22

# load cp0
mtc0 $s0, $23
mtc0 $s1, $14

# pop regs
lw $v0, ($sp)
addi $sp, $sp, -4
lw $a0, ($sp)
addi $sp, $sp, -4
lw $t1, ($sp)
addi $sp, $sp, -4
lw $t0, ($sp)
addi $sp, $sp, -4
lw $s1, ($sp)
addi $sp, $sp, -4
lw $s0, ($sp)
addi $sp, $sp, -4

# enable interrupt
mtc0 $zero, $22

# return
eret
