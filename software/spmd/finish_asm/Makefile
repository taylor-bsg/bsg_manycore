bsg_tiles_X= 1
bsg_tiles_Y= 1 
bsg_global_X = 4
bsg_global_Y = 5
bsg_tiles_org_X = 3
bsg_tiles_org_Y = 2

all: main.run

include ../Makefile.include

RISCV_LINK_OPTS = -march=rv32imaf -nostdlib -nostartfiles 

main.riscv:  main.o 
	$(RISCV_LINK)  $< -o $@ $(RISCV_LINK_OPTS)

clean:
	-rm -rf *.o *.jou *.log *.pb bsg_manycore_io_complex_rom.v *.riscv *.wdb *.bin *.hex *.vec
	-rm -rf xsim.dir *.mem
	-rm -rf ./simv csrc simv.daidir ucli.key DVEfiles *.vpd


include ../../mk/Makefile.tail_rules

