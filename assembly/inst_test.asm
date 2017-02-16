.text
lui $a0, 0x1
syscall
addi $t0, $zero, 4
srlv $a0, $a0, $t0
syscall
lui $a0, 0x1
syscall
addi $t0, $zero, 0x1
addi $sp, $sp, 4
sw $a0, ($sp)
sh $t0, ($sp)
lw $a0, ($sp)
syscall
addi $sp, $sp, -4

addi $t0, $zero, 0
addi $a0, $zero, 1
blez $t0, l1
addi $a0, $zero, 2
l1:
syscall

addi $t0, $zero, -1
addi $a0, $zero, 3
blez $t0, l2
addi $a0, $zero, 4
l2:
syscall

addi $t0, $zero, 1
addi $a0, $zero, 5
blez $t0, l3
addi $a0, $zero, 6
l3:
syscall
