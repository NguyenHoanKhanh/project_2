`ifndef CONNECT_FET_DE_V
`define CONNECT_FET_DE_V
`include "./source/fetch_stage.v"
`include "./source/decoder_stage.v"

module connect #(
    parameter IWIDTH = 32,
    parameter DEPTH = 100,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3,
    parameter DWIDTH = 32
)(
    c_clk, c_rst, fi_i_stall, fi_i_flush, fi_i_ce, fi_o_instr_fetch, ds_data_out_rs2, ds_data_out_rs1,
    ds_data_in_rd, ds_o_opcode, ds_o_alu, ds_o_imm, ds_o_funct3, ds_o_addr_rd_p, ds_o_addr_rs1_p, 
    ds_o_addr_rs2_p, ds_we, ds_read_reg
);
    input c_clk, c_rst;
    output [IWIDTH - 1 : 0] fi_o_instr_fetch;
    wire [AWIDTH_INSTR - 1 : 0] fi_o_addr_instr;
    wire fi_change_pc; 
    wire [PC_WIDTH - 1 : 0] fi_alu_pc_value;
    wire [PC_WIDTH - 1 : 0] fi_pc;
    input fi_i_stall;
    wire fi_o_stall;
    wire fi_o_ce;
    input fi_i_flush;
    wire fi_o_flush;
    input fi_i_ce;
    input ds_read_reg;
    input ds_we;
    output [DWIDTH - 1 : 0] ds_data_out_rs2;
    output [DWIDTH - 1 : 0] ds_data_out_rs1;
    input [DWIDTH - 1 : 0] ds_data_in_rd;
    wire ds_o_flush;
    wire ds_o_stall;
    wire ds_o_ce;
    wire [3 : 0] ds_o_exception;
    output [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    output [`ALU_WIDTH - 1 : 0] ds_o_alu;
    output [DWIDTH - 1 : 0] ds_o_imm;
    output [FUNCT_WIDTH - 1 : 0] ds_o_funct3;
    output [AWIDTH - 1 : 0] ds_o_addr_rd_p;
    output [AWIDTH - 1 : 0] ds_o_addr_rs2_p;
    output [AWIDTH - 1 : 0] ds_o_addr_rs1_p;
    wire [PC_WIDTH - 1 : 0] ds_o_pc;

    fetch_i # (
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) fi (
        .fi_clk(c_clk), 
        .fi_rst(c_rst), 
        .fi_o_instr_fetch(fi_o_instr_fetch), 
        .fi_o_addr_instr(fi_o_addr_instr), 
        .fi_change_pc(fi_change_pc), 
        .fi_alu_pc_value(fi_alu_pc_value), 
        .fi_pc(fi_pc), 
        .fi_i_stall(fi_i_stall), 
        .fi_o_stall(fi_o_stall), 
        .fi_o_ce(fi_o_ce), 
        .fi_i_ce(fi_i_ce),
        .fi_i_flush(fi_i_flush), 
        .fi_o_flush(fi_o_flush)
    );

    decoder_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .IWIDTH(IWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ds (
        .ds_clk(c_clk), 
        .ds_rst(c_rst), 
        .ds_i_instr(fi_o_instr_fetch), 
        .ds_i_pc(fi_pc), 
        .ds_o_pc(ds_o_pc), 
        .ds_o_addr_rs1_p(ds_o_addr_rs1_p), 
        .ds_o_addr_rs2_p(ds_o_addr_rs2_p), 
        .ds_o_addr_rd_p(ds_o_addr_rd_p), 
        .ds_o_funct3(ds_o_funct3), 
        .ds_o_imm(ds_o_imm), 
        .ds_o_alu(ds_o_alu), 
        .ds_o_opcode(ds_o_opcode), 
        .ds_o_exception(ds_o_exception), 
        .ds_i_ce(fi_o_ce), 
        .ds_o_ce(ds_o_ce), 
        .ds_i_stall(fi_o_stall), 
        .ds_o_stall(ds_o_stall), 
        .ds_i_flush(fi_o_flush), 
        .ds_o_flush(ds_o_flush), 
        .ds_data_in_rd(ds_data_in_rd), 
        .ds_data_out_rs1(ds_data_out_rs1), 
        .ds_data_out_rs2(ds_data_out_rs2), 
        .ds_we(ds_we), 
        .ds_read_reg(ds_read_reg)
    );
endmodule

`endif 