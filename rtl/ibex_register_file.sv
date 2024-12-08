// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Top level module of the register file implementation
 */
 
 module ibex_register_file import ibex_pkg::*; #(
    parameter regfile_e                          RegFile           = RegFileFF,
    parameter bit                                RdataMuxCheck     = 0        ,
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
  
    if (RegFile == RegFileFF) begin : gen_regfile_ff
        ibex_register_file_ff #(
          .RV32E            (RV32E),
          .DataWidth        (RegFileDataWidth),
          .DummyInstructions(DummyInstructions),
          // SEC_CM: DATA_REG_SW.GLITCH_DETECT
          .WrenCheck        (RegFileWrenCheck),
          .RdataMuxCheck    (RegFileRdataMuxCheck),
          .WordZeroVal      (RegFileDataWidth'(prim_secded_pkg::SecdedInv3932ZeroWord))
        ) register_file_i (
          .clk_i (clk),
          .rst_ni(rst_ni),
    
          .test_en_i       (test_en_i),
          .dummy_instr_id_i(dummy_instr_id),
          .dummy_instr_wb_i(dummy_instr_wb),
    
          .raddr_a_i(rf_raddr_a),
          .rdata_a_o(rf_rdata_a_ecc),
          .raddr_b_i(rf_raddr_b),
          .rdata_b_o(rf_rdata_b_ecc),
          .waddr_a_i(rf_waddr_wb),
          .wdata_a_i(rf_wdata_wb_ecc),
          .we_a_i   (rf_we_wb),
          .err_o    (rf_alert_major_internal)
        );
      end else if (RegFile == RegFileFPGA) begin : gen_regfile_fpga
        ibex_register_file_fpga #(
          .RV32E            (RV32E),
          .DataWidth        (RegFileDataWidth),
          .DummyInstructions(DummyInstructions),
          // SEC_CM: DATA_REG_SW.GLITCH_DETECT
          .WrenCheck        (RegFileWrenCheck),
          .RdataMuxCheck    (RegFileRdataMuxCheck),
          .WordZeroVal      (RegFileDataWidth'(prim_secded_pkg::SecdedInv3932ZeroWord))
        ) register_file_i (
          .clk_i (clk),
          .rst_ni(rst_ni),
    
          .test_en_i       (test_en_i),
          .dummy_instr_id_i(dummy_instr_id),
          .dummy_instr_wb_i(dummy_instr_wb),
    
          .raddr_a_i(rf_raddr_a),
          .rdata_a_o(rf_rdata_a_ecc),
          .raddr_b_i(rf_raddr_b),
          .rdata_b_o(rf_rdata_b_ecc),
          .waddr_a_i(rf_waddr_wb),
          .wdata_a_i(rf_wdata_wb_ecc),
          .we_a_i   (rf_we_wb),
          .err_o    (rf_alert_major_internal)
        );
      end else if (RegFile == RegFileLatch) begin : gen_regfile_latch
        ibex_register_file_latch #(
          .RV32E            (RV32E),
          .DataWidth        (RegFileDataWidth),
          .DummyInstructions(DummyInstructions),
          // SEC_CM: DATA_REG_SW.GLITCH_DETECT
          .WrenCheck        (RegFileWrenCheck),
          .RdataMuxCheck    (RegFileRdataMuxCheck),
          .WordZeroVal      (RegFileDataWidth'(prim_secded_pkg::SecdedInv3932ZeroWord))
        ) register_file_i (
          .clk_i (clk),
          .rst_ni(rst_ni),
    
          .test_en_i       (test_en_i),
          .dummy_instr_id_i(dummy_instr_id),
          .dummy_instr_wb_i(dummy_instr_wb),
    
          .raddr_a_i(rf_raddr_a),
          .rdata_a_o(rf_rdata_a_ecc),
          .raddr_b_i(rf_raddr_b),
          .rdata_b_o(rf_rdata_b_ecc),
          .waddr_a_i(rf_waddr_wb),
          .wdata_a_i(rf_wdata_wb_ecc),
          .we_a_i   (rf_we_wb),
          .err_o    (rf_alert_major_internal)
        );
      end
    
  endmodule
  