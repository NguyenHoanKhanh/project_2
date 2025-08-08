`ifndef PROCESSING_UNIT
`define PROCESSING_UNIT
`include "./source/header.vh"
`include "./source/fetch_stage.v"
`include "./source/decoder_stage.v"
`include "./source/execute_stage.v"
`include "./source/memory_stage.v"
`include "./source/write_back_stage.v" 

module processing #(
    parameter IWIDTH = 32,
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32,
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter FUNCT_WIDTH = 3
) (
    pe_clk, pe_rst, pe_fi_i_ce, pe_fi_i_stall, pe_fi_i_flush, pe_fi_o_instr_fetch, pe_wb_o_rd_addr, pe_wb_o_rd_data
);
    input pe_clk, pe_rst;
    output [IWIDTH - 1 : 0] pe_fi_o_instr_fetch;
    wire [AWIDTH_INSTR - 1 : 0] pe_fi_o_addr_instr;
    wire pe_ex_o_change_pc;
    wire [PC_WIDTH - 1 : 0] pe_fi_alu_pc_value;
    wire [PC_WIDTH - 1 : 0] pe_fi_pc;
    wire [PC_WIDTH - 1 : 0] pe_ds_o_pc;
    input pe_fi_i_stall;
    wire pe_fi_o_stall;
    input pe_fi_i_flush;
    wire pe_fi_o_flush;
    input pe_fi_i_ce;
    wire pe_fi_o_ce;
    wire ps_ds_read_reg;
    wire pe_ds_we;
    wire [DWIDTH - 1 : 0] pe_ds_data_out_rs2;
    wire [DWIDTH - 1 : 0] pe_ds_data_out_rs1;
    wire [DWIDTH - 1 : 0] pe_ds_data_in_rd;
    wire pe_ds_o_flush;
    wire pe_ds_o_stall;
    wire pe_ds_o_ce;
    wire [`EXCEPTION_WIDTH - 1 : 0] pe_ds_o_exception;
    wire [`OPCODE_WIDTH - 1 : 0] pe_ds_o_opcode;
    wire [`ALU_WIDTH - 1 : 0] pe_ds_o_alu;
    wire [DWIDTH - 1 : 0] pe_ds_o_imm;
    wire [FUNCT_WIDTH - 1 : 0] pe_ds_o_funct3;
    wire [AWIDTH - 1 : 0] pe_ds_o_addr_rd;
    wire [AWIDTH - 1 : 0] pe_ds_o_addr_rs2;
    wire [AWIDTH - 1 : 0] pe_ds_o_addr_rs1;
    wire pe_ex_stall_from_alu;
    wire pe_ex_o_valid;
    wire pe_ex_o_we_reg;
    wire [PC_WIDTH - 1 : 0] pe_ex_next_pc;
    wire [PC_WIDTH - 1 : 0] pe_ex_o_pc;
    wire pe_ex_o_flush;
    wire pe_ex_o_stall;
    wire pe_ex_o_ce;
    wire [11 : 0] pe_ex_o_imm;
    wire [FUNCT_WIDTH - 1 : 0] pe_ex_o_funct3;
    wire [`OPCODE_WIDTH - 1 : 0] pe_ex_o_opcode;
    wire [`ALU_WIDTH - 1 : 0] pe_ex_o_alu;
    wire [DWIDTH - 1 : 0] pe_ex_o_data_rd;
    wire [DWIDTH - 1 : 0] pe_ex_o_alu_value;
    wire [AWIDTH - 1 : 0] pe_ex_o_addr_rd;
    wire [`OPCODE_WIDTH - 1 : 0] pe_me_o_opcode;
    wire [AWIDTH - 1 : 0] pe_me_o_load_addr;
    wire [DWIDTH - 1 : 0] pe_me_o_store_data;
    wire [AWIDTH - 1 : 0] pe_me_o_store_addr;
    wire pe_me_o_we;
    wire pe_me_o_stb;
    wire pe_me_o_cyc;
    wire pe_me_o_flush;
    wire pe_me_o_stall;
    wire pe_me_o_ce;
    wire [AWIDTH - 1 : 0] pe_me_o_rd_addr;
    wire [DWIDTH - 1 : 0] pe_me_o_rd_data;
    wire pe_me_o_rd_we;
    wire [DWIDTH - 1 : 0] pe_me_o_load_data;
    wire [FUNCT_WIDTH - 1 : 0] pe_me_o_funct3;
    wire pe_wb_o_ce;
    input [DWIDTH - 1 : 0] pe_wb_i_csr;
    wire pe_wb_o_flush;
    wire pe_wb_o_stall;
    wire [PC_WIDTH - 1 : 0] pe_wb_o_next_pc;
    output [DWIDTH - 1 : 0] pe_wb_o_rd_data;
    output [AWIDTH - 1 : 0] pe_wb_o_rd_addr;
    

    fetch_i #(
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .DEPTH(DEPTH),
        .IWIDTH(IWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) fi (
        .fi_clk(pe_clk), 
        .fi_rst(pe_rst), 
        .fi_o_instr_fetch(pe_fi_o_instr_fetch), 
        .fi_o_addr_instr(pe_fi_o_addr_instr), 
        .fi_change_pc(pe_ex_o_change_pc), 
        .fi_alu_pc_value(pe_fi_alu_pc_value), 
        .fi_pc(pe_fi_pc), 
        .fi_i_stall(pe_fi_i_stall), 
        .fi_o_stall(pe_fi_o_stall), 
        .fi_i_ce(pe_fi_i_ce),
        .fi_o_ce(pe_fi_o_ce),
        .fi_i_flush(pe_fi_i_flush),
        .fi_o_flush(pe_fi_o_flush)
    );

    decoder_stage #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .IWIDTH(IWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ds (
        .ds_clk(pe_clk),
        .ds_rst(pe_rst),
        .ds_i_pc(pe_fi_pc),
        .ds_o_pc(pe_ds_o_pc),
        .ds_o_addr_rs1_p(pe_ds_o_addr_rs1),
        .ds_o_addr_rs2_p(pe_ds_o_addr_rs2),
        .ds_o_addr_rd_p(pe_ds_o_addr_rd),
        .ds_o_funct3(pe_ds_o_funct3),
        .ds_o_imm(pe_ds_o_imm),
        .ds_o_alu(pe_ds_o_alu),
        .ds_o_opcode(pe_ds_o_opcode),
        .ds_o_exception(pe_ds_o_exception),
        .ds_i_ce(pe_fi_o_ce),
        .ds_o_ce(pe_ds_o_ce),
        .ds_i_stall(pe_fi_o_stall),
        .ds_o_stall(pe_ds_o_stall),
        .ds_i_flush(pe_fi_o_flush),
        .ds_o_flush(pe_ds_o_flush),
        .ds_data_in_rd(pe_ds_data_in_rd),
        .ds_data_out_rs1(pe_ds_data_out_rs1),
        .ds_data_out_rs2(pe_ds_data_out_rs2),
        .ds_we(pe_ds_we),
        .ds_read_reg(ps_ds_read_reg)
    );

    execute # (
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) es (
        .ex_clk(pe_clk), 
        .ex_rst(pe_rst), 
        .ex_i_alu(pe_ds_o_alu), 
        .ex_i_opcode(pe_ds_o_opcode), 
        .ex_o_alu(pe_ex_o_alu), 
        .ex_o_opcode(pe_ex_o_opcode), 
        .ex_i_addr_rs1(pe_ds_o_addr_rs1), 
        .ex_i_addr_rs2(pe_ds_o_addr_rs2), 
        .ex_i_addr_rd(pe_ds_o_addr_rd), 
        .ex_i_data_rs1(pe_ds_data_out_rs1), 
        .ex_i_data_rs2(pe_ds_data_out_rs2), 
        .ex_o_data_rd(pe_ex_o_data_rd), 
        .ex_i_funct3(pe_ds_o_funct3), 
        .ex_o_funct3(pe_ex_o_funct3), 
        .ex_i_imm(pe_ds_o_imm), 
        .ex_o_imm(pe_ex_o_imm), 
        .ex_i_ce(pe_ds_o_ce), 
        .ex_o_ce(pe_ex_o_ce), 
        .ex_i_stall(pe_ds_o_stall), 
        .ex_o_stall(pe_ex_o_stall), 
        .ex_i_flush(pe_ds_o_flush),
        .ex_o_flush(pe_ex_o_flush), 
        .ex_i_pc(pe_ds_o_pc), 
        .ex_o_pc(pe_ex_o_pc), 
        .ex_next_pc(pe_ex_next_pc), 
        .ex_o_change_pc(pe_ex_o_change_pc),
        .ex_o_we_reg(pe_ex_o_we_reg), 
        .ex_o_valid(pe_ex_o_valid), 
        .ex_stall_from_alu(pe_ex_stall_from_alu),
        .ex_o_alu_value(pe_ex_o_alu_value),
        .ex_o_addr_rd(pe_ex_o_addr_rd)
    );

    mem_stage # (
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ms (
        .me_o_opcode(pe_me_o_opcode), 
        .me_i_opcode(pe_ex_o_opcode), 
        .me_o_load_addr(pe_me_o_load_addr), 
        .me_o_store_data(pe_me_o_store_data), 
        .me_o_store_addr(pe_me_o_store_addr), 
        .me_o_we(pe_me_o_we), 
        .me_o_stb(pe_me_o_stb), 
        .me_o_cyc(pe_me_o_cyc), 
        .me_i_rs2_data(pe_ds_data_out_rs2), 
        .me_i_alu_value(pe_ex_o_alu_value), 
        .me_o_flush(pe_me_o_flush), 
        .me_i_flush(pe_ex_o_flush), 
        .me_o_stall(pe_me_o_stall), 
        .me_i_stall(pe_ex_o_stall),
        .me_o_ce(pe_me_o_ce), 
        .me_i_ce(pe_ex_o_ce), 
        .me_rst(pe_rst), 
        .me_clk(pe_clk), 
        .me_i_rd_data(pe_ex_o_data_rd), 
        .me_i_rd_addr(pe_ex_o_addr_rd), 
        .me_o_rd_addr(pe_me_o_rd_addr), 
        .me_o_rd_data(pe_me_o_rd_data), 
        .me_o_rd_we(pe_me_o_rd_we), 
        .me_i_funct3(pe_ex_o_funct3),
        .me_o_load_data(pe_me_o_load_data),
        .me_o_funct3(pe_me_o_funct3)
    );

    writeback # (
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) wb (
        .wb_clk(pe_clk), 
        .wb_rst(pe_rst), 
        .wb_i_opcode(pe_me_o_opcode), 
        .wb_i_data_load(pe_me_o_load_data), 
        .wb_i_we_rd(pe_me_o_rd_we), 
        .wb_o_we_rd(pe_wb_o_we_rd), 
        .wb_i_we(pe_me_o_we), 
        .wb_o_we(pe_wb_o_we), 
        .wb_i_rd_addr(pe_me_o_rd_addr), 
        .wb_o_rd_addr(pe_wb_o_rd_addr), 
        .wb_i_rd_data(pe_me_o_rd_data), 
        .wb_o_rd_data(pe_wb_o_rd_data), 
        .wb_i_pc(pe_ex_o_pc), 
        .wb_o_next_pc(pe_wb_o_next_pc), 
        .wb_o_change_pc(pe_wb_o_change_pc), 
        .wb_i_ce(pe_me_o_ce), 
        .wb_o_stall(pe_wb_o_stall), 
        .wb_o_flush(pe_wb_o_flush), 
        .wb_i_csr(pe_wb_i_csr), 
        .wb_i_funct(pe_me_o_funct3), 
        .wb_i_flush(pe_me_o_flush), 
        .wb_i_stall(pe_me_o_stall), 
        .wb_o_ce(pe_wb_o_ce)
    );
endmodule
`endif 