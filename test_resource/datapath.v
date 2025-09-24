`ifndef DATAPATH_V
`define DATAPATH_V
`include "write_back.v"
`include "connect_fet_de_ex_mem.v"
module datapath #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3,
    parameter IWIDTH = 32,
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    d_clk, d_rst, d_i_ce, d_i_stall, d_i_flush, d_o_flush_n, d_o_stall_n, 
    d_o_addr_rd_n, d_o_data_rd_n, d_o_pc_n, d_o_opcode_n, d_o_funct3_n, d_o_change_pc_n
);
    input d_clk, d_rst;
    input d_i_ce;
    input d_i_stall, d_i_flush;
    
    output [AWIDTH - 1 : 0] d_o_addr_rd_n;
    output [DWIDTH - 1 : 0] d_o_data_rd_n;
    output [PC_WIDTH - 1 : 0] d_o_pc_n;
    output d_o_stall_n, d_o_flush_n;
    output [FUNCT_WIDTH - 1 : 0] d_o_funct3_n;
    output [`OPCODE_WIDTH - 1 : 0] d_o_opcode_n;
    output d_o_change_pc_n;

    wire [PC_WIDTH - 1 : 0] d_o_pc;
    wire [`OPCODE_WIDTH - 1 : 0] d_o_opcode;
    wire [FUNCT_WIDTH - 1 : 0] d_o_funct3;
    wire [AWIDTH - 1 : 0] d_o_addr_rd;
    wire [DWIDTH - 1 : 0] d_o_data_rd;
    wire [DWIDTH - 1 : 0] d_o_load_data;
    wire d_o_stall, d_o_flush;
    wire d_o_ce;
    wire d_o_ce_n;
    wire d_o_rd_we;
    wire d_o_change_pc;
	 wire d_o_rd_we_n;

    connect_fet_de_ex_mem #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) cm (
        .fm_clk(d_clk), 
        .fm_rst(d_rst), 
        .fm_i_ce(d_i_ce), 
        .fm_i_stall(d_i_stall), 
        .fm_i_flush(d_i_flush), 
        .fm_o_flush_n(d_o_flush), 
        .fm_o_stall_n(d_o_stall),  
        .fm_o_opcode_n(d_o_opcode),
        .fm_o_ce_n(d_o_ce), 
        .fm_o_funct3_n(d_o_funct3), 
        .fm_o_rd_addr(d_o_addr_rd), 
        .fm_o_rd_data(d_o_data_rd), 
        .fm_o_rd_we(d_o_rd_we), 
        .fm_o_load_data(d_o_load_data),
        .fm_pc_n(d_o_pc),
        .fm_change_pc(d_o_change_pc)
    );

    write_back #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) wb (
        .wb_clk(d_clk), 
        .wb_rst(d_rst), 
        .wb_i_opcode(d_o_opcode), 
        .wb_i_data_load(d_o_load_data), 
        .wb_i_we_rd(d_o_rd_we), 
        .wb_o_we_rd(d_o_rd_we_n), 
        .wb_i_pc(d_o_pc), 
        .wb_i_ce(d_o_ce), 
        .wb_i_rd_addr(d_o_addr_rd), 
        .wb_i_rd_data(d_o_data_rd), 
        .wb_i_change_pc(d_o_change_pc),
        .wb_i_funct(d_o_funct3), 
        .wb_i_stall(d_o_stall), 
        .wb_i_flush(d_o_flush), 
        .wb_o_rd_addr(d_o_addr_rd_n), 
        .wb_o_rd_data(d_o_data_rd_n), 
        .wb_o_next_pc(d_o_pc_n), 
        .wb_o_change_pc(d_o_change_pc_n), 
        .wb_o_stall(d_o_stall_n), 
        .wb_o_flush(d_o_flush_n), 
        .wb_o_ce(d_o_ce_n),
        .wb_o_opcode(d_o_opcode_n),
        .wb_o_funct(d_o_funct3_n)
    );
endmodule
`endif 