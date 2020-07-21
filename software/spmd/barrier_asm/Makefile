bsg_tiles_X= 4
bsg_tiles_Y= 4 

all: main.run

include ../Makefile.include

RISCV_LINK_OPTS = -march=rv32imaf -nostdlib -nostartfiles 

main.riscv: $(LINK_SCRIPT)  main.o $(BSG_MANYCORE_LIB)
	$(RISCV_LINK)  main.o -o $@ $(RISCV_LINK_OPTS) -L. -l:bsg_manycore_lib.a


include ../../mk/Makefile.tail_rules

