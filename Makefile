TEST_RESULT = $(patsubst %.v, %.vcd, $(wildcard *_test.v))

.PHONY:all
all:$(TEST_RESULT) cpu.vcd

cpu.vcd:cpu.vvp
	vvp -n $^

cpu.vvp:cpu.v alu.v controller.v register.v falling_edge_register.v regfile.v ram.v rom.v
	iverilog -o $@ $^

$(TEST_RESULT):%.vcd:%.vvp
	vvp -n $<

%_test.vvp:%_test.v %.v
	iverilog -o $@ $^

.PHONY:clean
clean:
	rm *.vvp *.vcd
