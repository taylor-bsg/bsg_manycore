`define SPMD      ????             // test program to be loaded
`define ROM(spmd) bsg_rom_``spmd`` // ROM contaning the spmd

module test_bsg_vscale_tile_array;

import  bsg_vscale_pkg::*  // vscale constants
       ,bsg_noc_pkg   ::*; // {P=0, W, E, N, S}

  localparam max_cycles_lp   = 1000000;
  localparam mem_size_lp     = 131072; 
  localparam bank_size_lp    = 16384;
  localparam num_banks_lp    = 4;
  localparam fifo_els_lp     = 10;
  localparam dirs_lp         = 4;
  localparam data_width_lp   = 32;
  localparam addr_width_lp   = 32;
  localparam num_tiles_x_lp  = 1;
  localparam num_tiles_y_lp  = 1;
  localparam lg_node_x_lp    = `BSG_SAFE_CLOG2(num_tiles_x_lp);
  localparam lg_node_y_lp    = `BSG_SAFE_CLOG2(num_tiles_y_lp + 1);
  localparam packet_width_lp = 6 + lg_node_x_lp + lg_node_y_lp
                                  + data_width_lp + addr_width_lp;
  localparam cycle_time_lp   = 20;

  // clock and reset generation
  wire clk;
  wire reset;
  
  bsg_nonsynth_clock_gen #( .cycle_time_p(cycle_time_lp)
                          ) clock_gen
                          ( .o(clk)
                          );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(10)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );
  

  logic [63:0]  trace_count;
  logic [63:0]  load_count;
  logic [255:0] reason;
  integer       stderr = 32'h80000002;

  logic [addr_width_lp-1:0]   mem_addr;
  logic [data_width_lp-1:0]   mem_data;

  logic [packet_width_lp-1:0] test_packet_in;
  logic                       test_valid_in;
  
  logic [S:N][num_tiles_x_lp-1:0][packet_width_lp-1:0] ver_packet_in;
  logic [S:N][num_tiles_x_lp-1:0]                      ver_valid_in;
  logic [S:N][num_tiles_x_lp-1:0]                      ver_yumi_in;                                                                   
  logic [E:W][num_tiles_y_lp-1:0][packet_width_lp-1:0] hor_packet_in;
  logic [E:W][num_tiles_y_lp-1:0]                      hor_valid_in;
  logic [E:W][num_tiles_y_lp-1:0]                      hor_ready_out;
  logic [E:W][num_tiles_y_lp-1:0]                      hor_yumi_in;   

  logic [num_tiles_y_lp-1:0][num_tiles_x_lp-1:0]                      htif_pcr_resp_valid;
  logic [num_tiles_y_lp-1:0][num_tiles_x_lp-1:0][`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data;

  bsg_vscale_tile_array #
    ( .dirs_p       (dirs_lp)
     ,.bank_size_p  (bank_size_lp)
     ,.num_banks_p  (num_banks_lp)
     ,.fifo_els_p   (fifo_els_lp)
     ,.data_width_p (data_width_lp)
     ,.addr_width_p (addr_width_lp)
     ,.num_tiles_x_p(num_tiles_x_lp)
     ,.num_tiles_y_p(num_tiles_y_lp)
     ,.stub_w_p     ({{(num_tiles_y_lp-1){1'b1}}, 1'b0})
     ,.stub_e_p     ({num_tiles_y_lp{1'b1}})
     ,.stub_n_p     ({num_tiles_x_lp{1'b1}}) // loads through N-side of (0,0)
     ,.stub_s_p     ({num_tiles_x_lp{1'b1}})
    ) UUT
    ( .clk_i   (clk)
     ,.reset_i (reset)

     ,.ver_packet_i (ver_packet_in)
     ,.ver_valid_i  (ver_valid_in)
     ,.ver_ready_o  ()
     ,.ver_packet_o ()
     ,.ver_valid_o  ()
     ,.ver_yumi_i   (ver_yumi_in)

     ,.hor_packet_i (hor_packet_in) 
     ,.hor_valid_i  (hor_valid_in)
     ,.hor_ready_o  (hor_ready_out)                                      
     ,.hor_packet_o ()
     ,.hor_valid_o  ()
     ,.hor_yumi_i   (hor_yumi_in)   

     ,.htif_pcr_resp_valid_o (htif_pcr_resp_valid)
     ,.htif_pcr_resp_data_o  (htif_pcr_resp_data)
    );

  bsg_manycore_spmd_loader
    #( .mem_size_p    (mem_size_lp)
      ,.num_rows_p    (num_tiles_y_lp)
      ,.num_cols_p    (num_tiles_x_lp)
      ,.data_width_p  (data_width_lp)
      ,.addr_width_p  (addr_width_lp)
      ,.tile_id_ptr_p (-1)
     ) spmd_loader
     ( .clk_i   (clk)
      ,.reset_i (reset)
      ,.packet_o(test_packet_in)
      ,.valid_o (test_valid_in )
      ,.ready_i (hor_ready_out[W][0])
      ,.data_i  (mem_data)
      ,.addr_o  (mem_addr)
     );

  `ROM(`SPMD)
    #( .addr_width_p(addr_width_lp)
      ,.width_p     (data_width_lp)
     ) spmd_rom
     ( .addr_i (mem_addr)
      ,.data_o (mem_data)
     );

  assign ver_packet_in = (2*num_tiles_x_lp*packet_width_lp)'(0);
  assign ver_valid_in  = (2*num_tiles_x_lp)'(0);
  assign ver_yumi_in   = (2*num_tiles_x_lp)'(0);
  assign hor_packet_in = (2*num_tiles_y_lp*packet_width_lp)'(0) | test_packet_in;
  assign hor_valid_in  = (2*num_tiles_y_lp)'(0) | test_valid_in;
  assign hor_yumi_in   = (2*num_tiles_y_lp)'(0);

  always_ff @(posedge clk) 
  begin
    if(reset)
      begin
        reason      <= 0;
        trace_count <= 0;
      end
    else
      begin
        trace_count = trace_count + 1;

        if (max_cycles_lp > 0 && trace_count > max_cycles_lp)
          reason = "timeout";
      end
  end


  logic [num_tiles_y_lp-1:0][num_tiles_x_lp-1:0] finish_r;

  always_ff @(posedge clk)
  begin
    if(reset)
      finish_r <= 0;

    for(int r=0; r<num_tiles_y_lp; r=r+1)
      for(int c=0; c<num_tiles_x_lp; c=c+1)
        if (!reset) 
          if (htif_pcr_resp_valid[r][c] && htif_pcr_resp_data[r][c] != 0) 
            if (htif_pcr_resp_data[r][c] == 1) 
              finish_r[r][c] <= 1'b1;
            else
               $sformat(reason, "tile: (%d, %d) tohost = %d", r, c, htif_pcr_resp_data[r][c] >> 1);

    if(&finish_r)
      begin
        $display("finished in %0d cycles", trace_count);
        $finish;
      end

    if (reason) 
    begin
       $error("*** FAILED *** (%0s) after %0d cycles", reason, trace_count);
       $finish;
    end
  end

endmodule