//                                      //   
//   Scalar Operand Network primitives  //
//                                      //


#include "bsg_manycore_arch.h"
#include "bsg_manycore_asm.h"

bsg_asm_finish(0,0)
loop:
  beq x0, x0, loop

//    barrier routine
//    a0 = reservation address
barrier:
  fence
  //fbar.son f0, f0

  la t0, __bsg_id
  lw t0, 0(t0)
  li t1, (bsg_tiles_X*bsg_tiles_Y)-1  

  beq t0, t1, __barrier_last_tile
  bne t0, x0, __barrier_root_tile 
  j __barrier_end                   // middle tiles jump here to the end.

__barrier_root_tile:
  sw x0, 0(a0)                      // initialize to the end

__barrier_root_tile_loop:
  lr.w t0, 0(a0)
  bne t0, x0, __barrier_root_tile_end
  lr.w.aq t0, 0(a0)
  beq t0, x0, __barrier_root_tile_loop

__barrier_root_tile_end:
  //fbar.son f0, f0
  j __barrier_end

__barrier_last_tile:
  lui t0, 0x20000
  or t0, a0, t0                     // root tile's reservation addr
  li t1, 1
  sw t1, 0(t0)                      // wake up the root tile

__barrier_end: 
  //fbar.son f0, f0
  ret



//    reduction
//    a0 = source array
reduction:
  











