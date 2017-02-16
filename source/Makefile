TEST_RESULT = $(patsubst %.v, %.vcd, $(wildcard *_test.v))

.PHONY:all
all:cpu.vcd

cpu.vcd:cpu.vvp benchmark.txt ISR2.txt ISR3.txt
	vvp -n $<

cpu.vvp:cpu.v alu.v controller.v register.v regfile.v ram.v rom.v interrupt_driver.v
	iverilog -o $@ $^

.PHONY:test
test:$(TEST_RESULT)

$(TEST_RESULT):%.vcd:%.vvp
	vvp -n $<

%_test.vvp:%_test.v %.v
	iverilog -o $@ $^

.PHONY:clean
clean:
	rm *.vvp *.vcd
