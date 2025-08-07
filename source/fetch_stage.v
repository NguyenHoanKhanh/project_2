`ifndef FETCH_STAGE_V
`define FETCH_STAGE_V
`include "./source/fetch_instruction.v"
`include "./source/transmit_instruction.v"

module fetch_i #(
    parameter IWIDTH = 32, 
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    fi_clk, fi_rst, fi_o_instr_fetch, fi_o_addr_instr, fi_change_pc, fi_alu_pc_value, 
    fi_pc, fi_i_stall, fi_o_stall, fi_o_ce, fi_i_flush, fi_o_flush
);
    input fi_clk, fi_rst;
    output [IWIDTH - 1 : 0] fi_o_instr_fetch;
    output [AWIDTH_INSTR - 1 : 0] fi_o_addr_instr;
    input fi_change_pc;
    input [PC_WIDTH - 1 : 0] fi_alu_pc_value;
    output [PC_WIDTH - 1 : 0] fi_pc;
    input fi_i_stall;
    output fi_o_stall;
    input fi_i_flush;
    output fi_o_flush;
    output fi_o_ce;
    wire [IWIDTH - 1 : 0] fi_o_instr_mem;

    wire fi_i_syn;
    wire fi_o_ack;

    transmit #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH)
    ) t (
        .t_clk(fi_clk),
        .t_rst(fi_rst),
        .t_i_syn(fi_i_syn),
        .t_o_instr(fi_o_instr_mem),
        .t_o_ack(fi_o_ack)
    );

    instruction_fetch #(
        .IWIDTH(IWIDTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) f (
        .f_clk(fi_clk),
        .f_rst(fi_rst),
        .f_i_instr(fi_o_instr_mem),
        .f_o_instr(fi_o_instr_fetch),
        .f_o_addr_instr(fi_o_addr_instr),
        .f_change_pc(fi_change_pc),
        .f_alu_pc_value(fi_alu_pc_value),
        .f_pc(fi_pc),
        .f_o_syn(fi_i_syn),
        .f_i_ack(fi_o_ack),
        .f_i_stall(fi_i_stall),
        .f_o_ce(fi_o_ce),
        .f_o_stall(fi_o_stall),
        .f_o_flush(fi_o_flush),
        .f_i_flush(fi_i_flush)
    );
endmodule
`endif