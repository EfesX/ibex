// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Top level module of the register file implementation
 */
 
 module ibex_register_file import ibex_pkg::*; #(
    parameter regfile_e                          RegFile           = RegFileFF,
    parameter bit                                RV32E             = 0        ,
    parameter int       unsigned                 DataWidth         = 32       ,
    parameter bit                                DummyInstructions = 0        ,
    parameter bit                                WrenCheck         = 0        ,
    parameter logic              [DataWidth-1:0] WordZeroVal       = '0
  ) (
    // Clock and Reset
    input  logic                 clk_i           ,
    input  logic                 rst_ni          ,
    input  logic                 test_en_i       ,
    input  logic                 dummy_instr_id_i,
    input  logic                 dummy_instr_wb_i,
    //Read port R1
    input  logic [          4:0] raddr_a_i       ,
    output logic [DataWidth-1:0] rdata_a_o       ,
    //Read port R2
    input  logic [          4:0] raddr_b_i       ,
    output logic [DataWidth-1:0] rdata_b_o       ,
    // Write port W1
    input  logic [          4:0] waddr_a_i       ,
    input  logic [DataWidth-1:0] wdata_a_i       ,
    input  logic                 we_a_i          ,
    // This indicates whether spurious WE are detected.
    output logic                 err_o
  );
  
    localparam int unsigned ADDR_WIDTH = RV32E ? 4 : 5;
    localparam int unsigned NUM_WORDS  = 2**ADDR_WIDTH;
  
    if (WrenCheck) begin : gen_wren_check
      if (RegFile != RegFileFPGA) begin : gen_wren_check_fpga
        logic [NUM_WORDS-1:0] we_a_dec_buf;
        logic [NUM_WORDS-1:0] waddr_a_onehot;
  
        prim_buf #(.Width(NUM_WORDS)) u_prim_buf (
          .in_i (waddr_a_onehot),
          .out_o(we_a_dec_buf  )
        );
  
        prim_onehot_check #(
          .AddrWidth  (ADDR_WIDTH),
          .AddrCheck  (1         ),
          .EnableCheck(1         )
        ) u_prim_onehot_check (
          .clk_i (clk_i       ),
          .rst_ni(rst_ni      ),
          .oh_i  (we_a_dec_buf),
          .addr_i(waddr_a_i   ),
          .en_i  (we_a_i      ),
          .err_o (err_o       )
        );
      end else begin : gen_wren_check_ff_or_latch
        logic we_a_rf_fpga;
        assign err_o = we_a_rf_fpga && !we_a_i;
      end
    end else begin : gen_no_wren_check
      assign err_o = 1'b0;
    end
  
    if (RegFile == RegFileFPGA) begin : gen_regfile_fpga
      ibex_register_file_fpga # (
        .NumWords           (NUM_WORDS          ),
        .DataWidth          (DataWidth          ),
        .DummyInstructions  (DummyInstructions  )
      ) register_file_fpga (
        .clk_i              (clk_i              ),
        .rst_ni             (rst_ni             ),
        .test_en_i          (test_en_i          ),
        .dummy_instr_id_i   (dummy_instr_id_i   ),
        .dummy_instr_wb_i   (dummy_instr_wb_i   ),
        .raddr_a_i          (raddr_a_i          ),
        .rdata_a_o          (rdata_a_o          ),
        .raddr_b_i          (raddr_b_i          ),
        .rdata_b_o          (rdata_b_o          ),
        .waddr_a_i          (waddr_a_i          ),
        .wdata_a_i          (wdata_a_i          ),
        .we_a_i             (we_a_i             ),
        .we_a_o             (we_a_rf_fpga       )
      );
    end else if (RegFile == RegFileFF) begin : gen_regfile_ff
      ibex_register_file_ff # (
        .NumWords           (NUM_WORDS          ),
        .DataWidth          (DataWidth          ),
        .DummyInstructions  (DummyInstructions  )
      ) register_file_ff (
        .clk_i              (clk_i              ),
        .rst_ni             (rst_ni             ),
        .test_en_i          (test_en_i          ),
        .dummy_instr_id_i   (dummy_instr_id_i   ),
        .dummy_instr_wb_i   (dummy_instr_wb_i   ),
        .raddr_a_i          (raddr_a_i          ),
        .rdata_a_o          (rdata_a_o          ),
        .raddr_b_i          (raddr_b_i          ),
        .rdata_b_o          (rdata_b_o          ),
        .waddr_a_i          (waddr_a_i          ),
        .wdata_a_i          (wdata_a_i          ),
        .we_a_i             (we_a_i             ),
        .waddr_a_onehot_o   (waddr_a_onehot     )
      );
    end else if (RegFile == RegFileLatch) begin : gen_regfile_latch
      ibex_register_file_latch # (
        .NumWords           (NUM_WORDS          ),
        .DataWidth          (DataWidth          ),
        .DummyInstructions  (DummyInstructions  )
      ) ibex_register_file_latch (
        .clk_i              (clk_i              ),
        .rst_ni             (rst_ni             ),
        .test_en_i          (test_en_i          ),
        .dummy_instr_id_i   (dummy_instr_id_i   ),
        .dummy_instr_wb_i   (dummy_instr_wb_i   ),
        .raddr_a_i          (raddr_a_i          ),
        .rdata_a_o          (rdata_a_o          ),
        .raddr_b_i          (raddr_b_i          ),
        .rdata_b_o          (rdata_b_o          ),
        .waddr_a_i          (waddr_a_i          ),
        .wdata_a_i          (wdata_a_i          ),
        .we_a_i             (we_a_i             ),
        .waddr_a_onehot_o   (waddr_a_onehot     )
      );
    end
  endmodule
  