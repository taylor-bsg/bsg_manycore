
bsg_tiles_X = 3
bsg_tiles_Y = 3

#########################################################
#each bytes defines the core type
# 00: vanilla core
# 01  vscale  core
#TYPE_VEC="64'h01_01_01_01"

all: main.run

include ../Makefile.include

#########################################################
#            FPU OPTION
#     The number of horizon node must be two and must 
#     be vanilla core 
BSG_FPU_OP=0

OBJS= main.o bsg_set_tile_x_y.o

main.riscv:  $(OBJS) $(SPMD_COMMON_OBJECTS) ../common/crt.o 
	$(RISCV_LINK)  $(OBJS) -o $@ $(RISCV_LINK_OPTS)

clean:
	-rm -rf *.o *.jou *.log *.pb bsg_manycore_io_complex_rom.v main.riscv *.wdb main.bin main.hex
	-rm -rf xsim.dir
	-rm -rf ./simv csrc simv.daidir ucli.key DVEfiles *.vpd

main.o: Makefile

include ../../mk/Makefile.tail_rules
