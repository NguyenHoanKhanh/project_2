`ifndef CSR_STAGE_V
`define CSR_STAGE_V
`include "./source/header.vh"
module control_status_register #(
    parameter FUNCT_WIDTH = 3,
    parameter DWIDTH = 32,
    parameter AWIDTH_CSR = 12,
    parameter PC_WIDTH = 32,
    parameter AWIDTH = 5
)(
    cs_clk, cs_rst, cs_i_opcode, cs_i_funct3, cs_i_stall, cs_i_flush, cs_i_opcode, cs_i_addr, cs_i_data_rs1
);
    input cs_clk, cs_rst;
    input cs_i_ce;
    input cs_i_stall, cs_i_flush;
    input [`OPCODE_WIDTH - 1 : 0] cs_i_opcode;
    input [FUNCT_WIDTH - 1 : 0] cs_i_funct3;
    input [AWIDTH_CSR - 1 : 0] cs_i_addr;
    input [DWIDTH - 1 : 0] cs_i_data_rs1;
    input [AWIDTH - 1 : 0] cs_i_addr_rd;

    wire op_system = cs_i_opcode[`SYSTEM];
endmodule
`endif 