`ifndef PROCESSING_UNIT_V
`define PROCESSING_UNIT_V
`include "./source/forwarding.v"
`include "./source/fetch_stage.v"
`include "./source/decoder_stage.v"
`include "./source/execute_stage.v"
`include "./source/memory_stage.v"
`include "./source/write_back_stage.v"
`include "./source/header.vh"

module processing #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3,
    parameter IWIDTH = 32,
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    p_clk, p_rst, p_i_stall, p_i_flush, p_i_ce, p_o_ws_opcode, p_o_ws_funct3, p_o_ws_fw_ds_data_rd, p_o_ws_addr_rd, p_o_ws_next_pc,
    p_o_ws_flush, p_o_ws_stall
);
    input p_clk, p_rst;
    input p_i_ce;
    input p_i_stall, p_i_flush;
    output [`OPCODE_WIDTH - 1 : 0] p_o_ws_opcode;
    output [FUNCT_WIDTH - 1 : 0] p_o_ws_funct3;
    output [DWIDTH - 1 : 0] p_o_ws_fw_ds_data_rd;
    output [AWIDTH - 1 : 0] p_o_ws_addr_rd;
    output [PC_WIDTH - 1 : 0] p_o_ws_next_pc;
    output p_o_ws_stall, p_o_ws_flush;

    wire [DWIDTH - 1 : 0] p_o_fw_es_data_rs1, p_o_fw_es_data_rs2;
    wire p_o_fw_es_force_stall_out;
    
    forwarding #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) f (
        .h_clk(p_clk),
        .h_rst(p_rst),
        .h_data_reg_rs1(p_o_ds_fw_data_rs1), 
        .h_data_reg_rs2(p_o_ds_fw_data_rs2), 
        .h_decoder_addr_rs1(p_o_ds_fw_es_addr_rs1), 
        .h_decoder_addr_rs2(p_o_ds_fw_es_addr_rs2),
        .h_alu_force_stall_out(p_o_fw_es_force_stall_out), 
        .h_data_out_rs1(p_o_fw_es_data_rs1), 
        .h_data_out_rs2(p_o_fw_es_data_rs2), 
        .h_i_valid_alu(p_o_es_fw_valid), 
        .h_i_we_reg_alu(p_o_es_fw_ms_we_reg),
        .h_i_alu_addr_rd(p_o_es_fw_ms_addr_rd), 
        .h_i_alu_data_rd(p_o_es_fw_ms_data_rd), 
        .h_i_memoryaccess_ce(p_o_es_fw_ms_ce), 
        .h_i_we_reg_mem(p_o_ms_fw_ws_we_reg), 
        .h_i_addr_rd_mem(p_o_ms_fw_ws_addr_rd), 
        .h_i_wb_ce(p_o_ms_fw_ws_ce),
        .h_i_data_rd_wb(p_o_ws_fw_ds_data_rd)
    );

    wire p_o_fs_ds_stall, p_o_fs_ds_flush;
    wire p_o_fs_ds_ce;
    wire [PC_WIDTH - 1 : 0] p_o_fs_ds_pc;
    wire [AWIDTH_INSTR - 1 : 0] p_o_fs_addr_instr;
    wire [IWIDTH - 1 : 0] p_o_fs_ds_instr;

    fetch_i #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) fs (
        .fi_clk(p_clk), 
        .fi_rst(p_rst), 
        .fi_i_stall(p_i_stall), 
        .fi_i_flush(p_i_flush), 
        .fi_i_ce(p_i_ce), 
        .fi_o_stall(p_o_fs_ds_stall), 
        .fi_o_ce(p_o_fs_ds_ce), 
        .fi_o_flush(p_o_fs_ds_flush),
        .fi_o_instr_fetch(p_o_fs_ds_instr), 
        .fi_o_addr_instr(p_o_fs_addr_instr), 
        .fi_change_pc(p_o_ws_fs_change_pc), 
        .fi_alu_pc_value(p_o_es_fs_next_pc), 
        .fi_pc(p_o_fs_ds_pc)
    );

    wire [PC_WIDTH - 1 : 0] p_o_ds_es_pc;
    wire [AWIDTH - 1 : 0] p_o_ds_fw_es_addr_rs1, p_o_ds_fw_es_addr_rs2, p_o_ds_es_addr_rd;
    wire [FUNCT_WIDTH - 1 : 0] p_o_ds_es_funct3;
    wire [DWIDTH - 1 : 0] p_o_ds_es_imm;
    wire [`ALU_WIDTH - 1 : 0] p_o_ds_es_alu;
    wire [`OPCODE_WIDTH - 1 : 0] p_o_ds_es_opcode;
    wire [`EXCEPTION_WIDTH - 1 : 0] p_o_exception;
    wire p_o_ds_es_ce;
    wire p_o_ds_es_stall, p_o_ds_es_flush;
    wire [DWIDTH - 1 : 0] p_o_ds_fw_data_rs1, p_o_ds_fw_data_rs2;
    wire p_i_wb_we_reg;

    decoder_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .IWIDTH(IWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ds (
        .ds_clk(p_clk), 
        .ds_rst(p_rst), 
        .ds_i_instr(p_o_fs_ds_instr), 
        .ds_i_pc(p_o_fs_ds_pc), 
        .ds_o_pc(p_o_ds_es_pc), 
        .ds_o_addr_rs1_p(p_o_ds_fw_es_addr_rs1), 
        .ds_o_addr_rs2_p(p_o_ds_fw_es_addr_rs2), 
        .ds_o_addr_rd_p(p_o_ds_es_addr_rd), 
        .ds_o_funct3(p_o_ds_es_funct3), 
        .ds_o_imm(p_o_ds_es_imm), 
        .ds_o_alu(p_o_ds_es_alu), 
        .ds_o_opcode(p_o_ds_es_opcode), 
        .ds_o_exception(p_o_exception), 
        .ds_i_ce(p_o_fs_ds_ce), 
        .ds_o_ce(p_o_ds_es_ce), 
        .ds_i_stall(p_o_fs_ds_stall), 
        .ds_o_stall(p_o_ds_es_stall), 
        .ds_i_flush(p_o_fs_ds_flush), 
        .ds_o_flush(p_o_ds_es_flush), 
        .ds_data_in_rd(p_o_ws_fw_ds_data_rd), 
        .ds_data_out_rs1(p_o_ds_fw_data_rs1), 
        .ds_data_out_rs2(p_o_ds_fw_data_rs2), 
        .ds_we(p_i_wb_we_reg)  
    );

    wire [`ALU_WIDTH - 1 : 0] p_o_es_ms_alu;
    wire [`OPCODE_WIDTH - 1 : 0] p_o_es_ms_opcode;
    wire [DWIDTH - 1 : 0] p_o_es_fw_ms_data_rd;
    wire [FUNCT_WIDTH - 1 : 0] p_o_es_ms_funct3;
    wire [DWIDTH - 1 : 0] p_o_es_imm;
    wire p_o_es_fw_ms_ce;
    wire p_o_es_ms_stall, p_o_es_ms_flush;
    wire [PC_WIDTH - 1 : 0] p_o_es_ws_pc;
    wire [PC_WIDTH - 1 : 0] p_o_es_fs_next_pc;
    wire p_o_es_wb_change_pc;
    wire p_o_es_fw_ms_we_reg;
    wire p_o_es_fw_valid;
    wire p_o_es_ms_stall_from_alu;
    wire [DWIDTH - 1 : 0] p_o_es_ms_alu_value;
    wire [AWIDTH - 1 : 0] p_o_es_fw_ms_addr_rd;
    wire [AWIDTH - 1 : 0] p_o_es_addr_rs1, p_o_es_addr_rs2;
    wire [DWIDTH - 1 : 0] p_o_es_ms_data_rs1, p_o_es_ms_data_rs2;

    execute_stage #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) es (
        .ex_clk(p_clk), 
        .ex_rst(p_rst), 
        .ex_i_alu(p_o_ds_es_alu), 
        .ex_i_opcode(p_o_ds_es_opcode), 
        .ex_i_addr_rs1(p_o_ds_fw_es_addr_rs1), 
        .ex_i_addr_rs2(p_o_ds_fw_es_addr_rs2), 
        .ex_i_addr_rd(p_o_ds_es_addr_rd), 
        .ex_i_data_rs1(p_o_fw_es_data_rs1), 
        .ex_i_data_rs2(p_o_fw_es_data_rs2), 
        .ex_i_funct3(p_o_ds_es_funct3), 
        .ex_i_imm(p_o_ds_es_imm), 
        .ex_i_ce(p_o_ds_es_ce), 
        .ex_i_force_stall(p_o_fw_es_force_stall_out),
        .ex_i_stall(p_o_ds_es_stall), 
        .ex_i_flush(p_o_ds_es_flush), 
        .ex_i_pc(p_o_ds_es_pc), 
        .ex_o_alu(p_o_es_ms_alu), 
        .ex_o_opcode(p_o_es_ms_opcode), 
        .ex_o_funct3(p_o_es_ms_funct3), 
        .ex_o_imm(p_o_es_imm), 
        .ex_o_ce(p_o_es_fw_ms_ce), 
        .ex_o_stall(p_o_es_ms_stall), 
        .ex_o_flush(p_o_es_ms_flush), 
        .ex_o_pc(p_o_es_ws_pc), 
        .ex_next_pc(p_o_es_fs_next_pc), 
        .ex_o_change_pc(p_o_es_wb_change_pc),
        .ex_o_we_reg(p_o_es_fw_ms_we_reg), 
        .ex_o_valid(p_o_es_fw_valid), 
        .ex_stall_from_alu(p_o_es_ms_stall_from_alu), 
        .ex_o_alu_value(p_o_es_ms_alu_value), 
        .ex_o_addr_rd(p_o_es_fw_ms_addr_rd), 
        .ex_o_data_rd(p_o_es_fw_ms_data_rd), 
        .ex_o_addr_rs1(p_o_es_addr_rs1),
        .ex_o_addr_rs2(p_o_es_addr_rs2), 
        .ex_o_data_rs1(p_o_es_ms_data_rs1), 
        .ex_o_data_rs2(p_o_es_ms_data_rs2)
    );

    wire p_o_ms_fw_ws_ce;
    wire [FUNCT_WIDTH - 1 : 0] p_o_ms_ws_funct3;
    wire [`OPCODE_WIDTH - 1 : 0] p_o_ms_ws_opcode;
    wire [DWIDTH - 1 : 0] p_o_ms_ws_load_data;
    wire p_o_ms_ws_stall, p_o_ms_ws_flush;
    wire [AWIDTH - 1 : 0] p_o_ms_fw_ws_addr_rd;
    wire [DWIDTH - 1 : 0] p_o_ms_ws_data_rd;
    wire p_o_ms_fw_ws_we_reg;

    mem_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ms (
        .me_clk(p_clk), 
        .me_rst(p_rst), 
        .me_i_ce(p_o_es_fw_ms_ce), 
        .me_i_rd_data(p_o_es_fw_ms_data_rd), 
        .me_i_rd_addr(p_o_es_fw_ms_addr_rd), 
        .me_i_opcode(p_o_es_ms_opcode), 
        .me_i_rs2_data(p_o_es_ms_data_rs2), 
        .me_i_alu_value(p_o_es_ms_alu_value), 
        .me_i_flush(p_o_es_ms_flush), 
        .me_i_stall(p_o_es_ms_stall),
        .me_i_funct3(p_o_es_ms_funct3), 
        .me_stall_from_alu(p_o_es_ms_stall_from_alu),
        .me_o_ce(p_o_ms_fw_ws_ce), 
        .me_o_funct3(p_o_ms_ws_funct3),
        .me_o_opcode(p_o_ms_ws_opcode), 
        .me_o_load_data(p_o_ms_ws_load_data),
        .me_o_flush(p_o_ms_ws_flush), 
        .me_o_stall(p_o_ms_ws_stall), 
        .me_o_rd_addr(p_o_ms_fw_ws_addr_rd), 
        .me_o_rd_data(p_o_ms_ws_data_rd), 
        .me_o_rd_we(p_o_ms_fw_ws_we_reg)
    );

    wire p_o_ws_ds_we_reg;
    wire p_o_ws_fs_change_pc;
    wire p_o_ws_ce;

    write_back_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ws (
        .wb_clk(p_clk), 
        .wb_rst(p_rst), 
        .wb_i_opcode(p_o_ms_ws_opcode), 
        .wb_i_funct(p_o_ms_ws_funct3), 
        .wb_i_data_load(p_o_ms_ws_load_data), 
        .wb_i_we_rd(p_o_ms_fw_ws_we_reg), 
        .wb_i_rd_addr(p_o_ms_fw_ws_addr_rd), 
        .wb_i_rd_data(p_o_ms_ws_data_rd), 
        .wb_i_pc(p_o_es_ws_pc), 
        .wb_i_ce(p_o_ms_fw_ws_ce), 
        .wb_i_flush(p_o_ms_ws_flush), 
        .wb_i_stall(p_o_ms_ws_stall), 
        .wb_i_change_pc(p_o_es_wb_change_pc),
        .wb_o_we_rd(p_o_ws_ds_we_reg), 
        .wb_o_rd_addr(p_o_ws_addr_rd), 
        .wb_o_rd_data(p_o_ws_fw_ds_data_rd), 
        .wb_o_next_pc(p_o_ws_next_pc), 
        .wb_o_change_pc(p_o_ws_fs_change_pc), 
        .wb_o_stall(p_o_ws_stall), 
        .wb_o_flush(p_o_ws_flush), 
        .wb_o_ce(p_o_ws_ce),
        .wb_o_funct(p_o_ws_funct3), 
        .wb_o_opcode(p_o_ws_opcode)
    );
endmodule
`endif 