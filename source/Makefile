TEST_RESULT = $(patsubst %.v, %.vcd, $(wildcard *_test.v))

.PHONY:all
all:cpu_bridge.vcd

cpu_bridge.vcd:cpu_bridge.vvp benchmark.txt ISR2.txt ISR3.txt
	vvp -n $<

cpu_bridge.vvp:cpu_bridge.v cpu.v alu.v controller.v register.v regfile.v ram.v rom.v interrupt_driver.v even_divider.v encoder4_7.v TDM8.v
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
