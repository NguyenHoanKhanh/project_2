`ifndef CONNECT_FET_DE_EX_MEM_V
`define CONNECT_FET_DE_EX_MEM_V

`include "fetch_decoder_execute.v"
`include "mem_stage.v"
module connect_fet_de_ex_mem #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3,
    parameter IWIDTH = 32,
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    fm_clk, fm_rst, fm_i_ce, fm_i_stall, fm_i_flush, fm_o_flush_n, fm_o_opcode_n,
    fm_o_stall_n, fm_o_ce_n, fm_o_funct3_n, fm_o_rd_addr, fm_o_rd_data, 
    fm_o_rd_we, fm_o_load_data, fm_pc_n, fm_change_pc
);
    //Input control
    input fm_clk, fm_rst;
    input fm_i_ce;
    input fm_i_stall;
    input fm_i_flush;
    //Output 
    output [PC_WIDTH - 1 : 0] fm_pc_n;
    output [`OPCODE_WIDTH - 1 : 0] fm_o_opcode_n;
    output fm_o_ce_n, fm_o_stall_n, fm_o_flush_n;
    output [FUNCT_WIDTH - 1 : 0] fm_o_funct3_n;
    output [AWIDTH - 1 : 0] fm_o_rd_addr;
    output [DWIDTH - 1 : 0] fm_o_rd_data;
    output fm_o_rd_we;
    output [DWIDTH - 1 : 0] fm_o_load_data;
    output fm_change_pc;
    //Transient
    wire [`ALU_WIDTH - 1 : 0] fm_o_alu;
    wire [`OPCODE_WIDTH - 1 : 0] fm_o_opcode;
    wire [AWIDTH - 1 : 0] fm_o_addr_rd;
    wire [DWIDTH - 1 : 0] fm_o_data_rd;
    wire [FUNCT_WIDTH - 1 : 0] fm_o_funct3;
    wire [DWIDTH - 1 : 0] fm_o_imm;
    wire [PC_WIDTH - 1 : 0] fm_next_pc;
    wire [DWIDTH - 1 : 0] fm_alu_value;
    wire fm_o_stall;
    wire fm_o_flush;
    wire fm_stall_alu;
    wire fm_o_ce;
    wire [DWIDTH - 1 : 0] fm_o_data_rs1, fm_o_data_rs2;
    wire [AWIDTH - 1 : 0] fm_o_addr_rs1, fm_o_addr_rs2;
    wire fm_o_valid, fm_we_reg;
    wire fm_o_rd_we_temp;

    fetch_decoder_execute #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) fe (
        .fe_clk(fm_clk), 
        .fe_rst(fm_rst), 
        .fe_i_ce(fm_i_ce), 
        .fe_i_stall(fm_i_stall), 
        .fe_i_flush(fm_i_flush),
        .fe_o_alu(fm_o_alu), 
        .fe_o_opcode(fm_o_opcode), 
        .fe_o_addr_rd(fm_o_addr_rd), 
        .fe_o_data_rd(fm_o_data_rd),
        .fe_o_funct3(fm_o_funct3), 
        .fe_o_imm(fm_o_imm), 
        .fe_next_pc(fm_next_pc), 
        .fe_pc_n(fm_pc_n), 
        .fe_alu_value(fm_alu_value),
        .fe_o_stall_n(fm_o_stall), 
        .fe_o_flush_n(fm_o_flush), 
        .fe_o_ce_n(fm_o_ce), 
        .fe_stall_alu(fm_stall_alu),
        .fe_o_data_rs1(fm_o_data_rs1), 
        .fe_o_data_rs2(fm_o_data_rs2), 
        .fe_o_addr_rs1(fm_o_addr_rs1), 
        .fe_o_addr_rs2(fm_o_addr_rs2),
        .fe_o_valid(fm_o_valid), 
        .fe_we_reg(fm_o_rd_we_temp),
        .fe_we_reg_n(fm_we_reg),
        .fe_change_pc(fm_change_pc)
    );

    mem_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) ms (
        .me_clk(fm_clk), 
        .me_rst(fm_rst), 
        .me_i_opcode(fm_o_opcode), 
        .me_o_opcode(fm_o_opcode_n), 
        .me_i_rs2_data(fm_o_data_rs2), 
        .me_i_alu_value(fm_alu_value), 
        .me_o_flush(fm_o_flush_n), 
        .me_i_flush(fm_o_flush), 
        .me_o_stall(fm_o_stall_n), 
        .me_i_stall(fm_o_stall), 
        .me_o_ce(fm_o_ce_n), 
        .me_i_ce(fm_o_ce), 
        .me_i_rd_data(fm_o_data_rd), 
        .me_i_rd_addr(fm_o_addr_rd), 
        .me_o_funct3(fm_o_funct3_n),
        .me_o_rd_addr(fm_o_rd_addr), 
        .me_o_rd_data(fm_o_rd_data), 
        .me_o_rd_we(fm_o_rd_we), 
        .me_i_funct3(fm_o_funct3), 
        .me_o_load_data(fm_o_load_data),
        .me_we_reg_n(fm_we_reg)
    );

    assign fm_o_rd_we_temp = fm_o_rd_we;
endmodule
`endif