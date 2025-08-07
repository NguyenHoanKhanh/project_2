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
    pe_clk, pe_rst, pe_fi_o_instr_fetch
);
    input pe_clk, pe_rst;
    output [IWIDTH - 1 : 0] pe_fi_o_instr_fetch;
    wire [AWIDTH_INSTR - 1 : 0] pe_fi_o_addr_instr;
    wire pe_ex_o_change_pc;
    wire [PC_WIDTH - 1 : 0] pe_fi_alu_pc_value;
    wire [PC_WIDTH - 1 : 0] pe_fi_pc;
    wire [PC_WIDTH - 1 : 0] pe_ds_o_pc;
    wire pe_fi_i_stall;
    wire pe_fi_o_stall;
    reg pe_fi_i_flush;
    wire pe_fi_o_flush;
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
        .ex_stall_from_alu(pe_ex_stall_from_alu)
    );
endmodule
`endif 