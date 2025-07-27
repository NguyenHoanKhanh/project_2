`include "./source/decoder.v"
`include "./source/register_file.v"

`ifndef DECODER_STAGE_V
`define DECODER_STAGE_V

module decoder_stage #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter PC_WIDTH = 32,
    parameter IWIDTH = 32
)(
    ds_clk, ds_rst, ds_i_instr, ds_i_pc, ds_o_pc, ds_o_addr_rs1_p, ds_o_addr_rs2_p, ds_o_addr_rd_p, ds_o_funct3, ds_o_imm, ds_o_alu, ds_o_opcode, ds_o_exception, ds_i_ce, ds_o_ce, ds_i_stall, ds_o_stall, ds_i_flush, ds_o_flush, ds_data_in_rd, ds_data_out_rs1, ds_data_out_rs2, ds_we, ds_read_reg
);
    input ds_clk, ds_rst;
    input [IWIDTH - 1 : 0] ds_i_instr;
    input [PC_WIDTH - 1 : 0] ds_i_pc;
    output [PC_WIDTH - 1 : 0] ds_o_pc;
    output [AWIDTH - 1 : 0] ds_o_addr_rs1_p;
    output [AWIDTH - 1 : 0] ds_o_addr_rs2_p;
    output [AWIDTH - 1 : 0] ds_o_addr_rd_p;
    output [2 : 0] ds_o_funct3;
    output [DWIDTH - 1 : 0] ds_o_imm;
    output [`ALU_WIDTH - 1 : 0] ds_o_alu;
    output [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    output [`EXCEPTION_WIDTH - 1 : 0] ds_o_exception;
    input ds_i_ce;
    output ds_o_ce;
    input ds_i_stall;
    output ds_o_stall;
    input ds_i_flush;
    output ds_o_flush;
    input [DWIDTH - 1 : 0] ds_data_in_rd;
    output [DWIDTH - 1 : 0] ds_data_out_rs1;
    output [DWIDTH - 1 : 0] ds_data_out_rs2;
    input ds_we;
    input ds_read_reg;

    wire [AWIDTH - 1 : 0] ds_o_addr_rd;
    wire [AWIDTH - 1 : 0] ds_o_addr_rs1;
    wire [AWIDTH - 1 : 0] ds_o_addr_rs2;
    decoder # (
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .IWIDTH(IWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) d (
        .d_clk(ds_clk), 
        .d_rst(ds_rst), 
        .d_i_instr(ds_i_instr), 
        .d_i_pc(ds_i_pc),
        .d_o_pc(ds_o_pc), 
        .d_o_addr_rs1(ds_o_addr_rs1), 
        .d_o_addr_rs1_p(ds_o_addr_rs1_p), 
        .d_o_addr_rs2(ds_o_addr_rs2), 
        .d_o_addr_rs2_p(ds_o_addr_rs2_p), 
        .d_o_addr_rd(ds_o_addr_rd), 
        .d_o_addr_rd_p(ds_o_addr_rd_p), 
        .d_o_imm(ds_o_imm), 
        .d_o_funct3(ds_o_funct3), 
        .d_o_alu(ds_o_alu), 
        .d_o_opcode(ds_o_opcode), 
        .d_o_exception(ds_o_exception), 
        .d_i_ce(ds_i_ce), 
        .d_o_ce(ds_o_ce), 
        .d_i_stall(ds_i_stall), 
        .d_o_stall(ds_o_stall), 
        .d_i_flush(ds_i_flush), 
        .d_o_flush(ds_o_flush)
    );

    register #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) re (
        .r_clk(ds_clk), 
        .r_rst(ds_rst), 
        .r_addr_rs_1(ds_o_addr_rs1_p), 
        .r_addr_rs_2(ds_o_addr_rs2_p), 
        .r_addr_rd(ds_o_addr_rd_p), 
        .r_data_rd(ds_data_in_rd), 
        .r_data_out_rs1(ds_data_out_rs1), 
        .r_data_out_rs2(ds_data_out_rs2), 
        .r_we(ds_we), 
        .r_read_reg(ds_read_reg)
    );
endmodule
`endif 