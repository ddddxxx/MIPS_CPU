.PHONY:all
all:cpu.vcd

cpu.vcd:cpu.vvp
	vvp -n cpu.vvp

cpu.vvp:cpu.v
	iverilog -o cpu.vvp cpu.v

.PHONY:clean
clean:
	rm *.vvp *.vcd
