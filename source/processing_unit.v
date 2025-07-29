`ifndef PROCESSING_UNIT_V
`define PROCESSING_UNIT_V
`include "./source/fetch_stage.v"
`include "./source/decoder_stage.v"
`include "./source/stall.v"
module processing_unit#(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter DEPTH = 36,
    parameter PC_WIDTH = 32,
    parameter IWIDTH = 32
)(
    pe_clk, pe_rst, pe_o_instr, pe_o_addr_instr, pe_pc, pe_o_ce, pe_o_addr_rs1_p, pe_o_addr_rs2_p, pe_o_addr_rd_p, pe_o_funct3, pe_o_imm, pe_o_alu, pe_o_opcode, pe_o_exception, pe_o_flush, pe_data_in_rd, pe_data_out_rs1, pe_data_out_rs2
);
    input pe_clk, pe_rst;
    input [IWIDTH - 1 : 0] pe_o_instr;
    output [AWIDTH - 1 : 0] pe_o_addr_instr;
    output [PC_WIDTH - 1 : 0] pe_pc;
    wire [IWIDTH - 1 : 0] pe_o_instr_f;
    wire f_o_syn;
    wire f_i_ack;
    reg f_change_pc;
    reg [PC_WIDTH - 1 : 0] f_alu_pc_value;
    output pe_o_ce;
    wire ds_o_ce;
    wire [PC_WIDTH - 1 : 0] ds_o_pc;
    output [AWIDTH - 1 : 0] pe_o_addr_rs1_p;
    output [AWIDTH - 1 : 0] pe_o_addr_rs2_p;
    output [AWIDTH - 1 : 0] pe_o_addr_rd_p;
    output [2 : 0] pe_o_funct3;
    output [DWIDTH - 1 : 0] pe_o_imm;
    output [`ALU_WIDTH - 1 : 0] pe_o_alu;
    output [`OPCODE_WIDTH - 1 : 0] pe_o_opcode;
    output [`EXCEPTION_WIDTH - 1 : 0] pe_o_exception;
    wire pe_o_stall_ds;
    wire pe_o_stall_f;
    wire pe_o_stall_ex;
    wire pe_o_stall_mem;
    wire pe_o_stall_wb;
    reg ds_i_flush;
    output pe_o_flush;
    reg ds_we;
    reg ds_read_reg;
    input [DWIDTH - 1 : 0] pe_data_in_rd;
    output [DWIDTH - 1 : 0] pe_data_out_rs1;
    output [DWIDTH - 1 : 0] pe_data_out_rs2;

    stall_pipeline sp (
        .s_clk(pe_clk),
        .s_rst(pe_rst),
        .fetch_stall(pe_o_stall_f),
        .decode_stall(pe_o_stall_ds),
        .ex_stall(pe_o_stall_ex),
        .mem_stall(pe_o_stall_mem),
        .wb_stall(pe_o_stall_wb),
        .out_stall(pe_o_stall)
    );

    transmit #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH)
    ) ti (
        .t_clk(pe_clk),
        .t_rst(pe_rst),
        .t_o_instr(pe_o_instr),
        .t_i_syn(f_o_syn),
        .t_o_ack(f_i_ack)
    );

    instruction_fetch #(
        .IWIDTH(IWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) fs (
        .f_clk(pe_clk),
        .f_rst(pe_rst),
        .f_o_addr_instr(pe_o_addr_instr),
        .f_i_instr(pe_o_instr),
        .f_o_instr(pe_o_instr_f),
        .f_o_syn(f_o_syn),
        .f_i_ack(f_i_ack),
        .f_change_pc(f_change_pc),
        .f_alu_pc_value(f_alu_pc_value),
        .f_pc(pe_pc),
        .f_i_stall(out_stall),
        .f_o_ce(pe_o_ce),
        .f_o_stall(pe_o_stall_f)
    );

    decoder_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .IWIDTH(IWIDTH)
    ) ds (
        .ds_clk(pe_clk),
        .ds_rst(pe_rst),
        .ds_i_instr(pe_o_instr_f),
        .ds_i_pc(pe_pc),
        .ds_o_pc(ds_o_pc),
        .ds_o_addr_rs1_p(pe_o_addr_rs1_p),
        .ds_o_addr_rs2_p(pe_o_addr_rs2_p),
        .ds_o_addr_rd_p(pe_o_addr_rd_p),
        .ds_o_funct3(pe_o_funct3),
        .ds_o_imm(pe_o_imm),
        .ds_o_alu(pe_o_alu),
        .ds_o_opcode(pe_o_opcode),
        .ds_o_exception(pe_o_exception),
        .ds_i_ce(pe_o_ce),
        .ds_o_ce(ds_o_ce),
        .ds_i_stall(ds_i_stall),
        .ds_o_stall(pe_o_stall_ds),
        .ds_i_flush(ds_i_flush),
        .ds_o_flush(pe_o_flush),
        .ds_data_in_rd(pe_data_in_rd),
        .ds_data_out_rs1(pe_data_out_rs1),
        .ds_data_out_rs2(pe_data_out_rs2),
        .ds_we(ds_we),
        .ds_read_reg(ds_read_reg)
    );
endmodule
`endif 