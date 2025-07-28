`ifndef EXECUTE_STAGE_V
`define EXECUTE_STAGE_V
`include "./source/header.vh"

module execute #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter PC_WIDTH = 32
)(
    e_clk, e_rst, e_i_alu, e_i_addr_rs1, e_o_addr_rs1, e_i_rs1, e_o_rs1, e_i_rs2, e_o_rs2, e_i_imm, e_o_imm, e_i_funct3, e_o_funct3, e_i_opcode, e_o_opcode, e_i_exception, e_o_exception, e_o_result_alu, e_i_pc, e_o_pc, e_o_next_pc, e_o_change_pc, e_o_we, e_o_read_valid, e_i_addr_rd, e_o_addr_rd, e_o_data_rd
);
    input e_clk, e_rst;
    input [`ALU_WIDTH - 1 : 0] e_i_alu;
    input [AWIDTH - 1 : 0] e_i_addr_rs1;
    output reg [AWIDTH - 1 : 0] e_o_addr_rs1;
    input [DWIDTH - 1 : 0] e_i_rs1;
    output reg [DWIDTH - 1 : 0] e_o_rs1;
    input [DWIDTH - 1 : 0] e_i_rs2;
    output reg [DWIDTH - 1 : 0] e_o_rs2;
    input [DWIDTH - 1 : 0] e_i_imm;
    output [DWIDTH - 1 : 0] e_o_imm;
    input [2 : 0] e_i_funct3;
    output reg [2 : 0] e_o_funct3;
    input [`OPCODE_WIDTH - 1 : 0] e_i_opcode;
    output reg [`OPCODE_WIDTH - 1 : 0] e_o_opcode;
    input [`EXCEPTION_WIDTH - 1 : 0] e_i_exception;
    output reg [`EXCEPTION_WIDTH - 1 : 0] e_o_exception;
    output reg [DWIDTH - 1 : 0] e_o_result_alu;
    //PC control
    input [PC_WIDTH - 1 : 0] e_i_pc;
    output reg [PC_WIDTH - 1 : 0] e_o_pc;
    output reg [PC_WIDTH - 1 : 0] e_o_next_pc;
    output reg e_o_change_pc;
    //Register file control
    output reg e_o_we;
    output reg e_o_read_valid;
    input [AWIDTH - 1 : 0] e_i_addr_rd;
    output [AWIDTH - 1 : 0] e_o_addr_rd;
    output [DWIDTH - 1 : 0] e_o_data_rd;


    wire alu_add = e_i_alu[`ADD];
    wire alu_sub = e_i_alu[`SUB];
    wire alu_slt = e_i_alu[`SLT];
    wire alu_sltu = e_i_alu[`SLTU];
    wire alu_xor = e_i_alu[`XOR];
    wire alu_or = e_i_alu[`OR];
    wire alu_and = e_i_alu[`AND];
    wire alu_sll = e_i_alu[`SLL];
    wire alu_srl = e_i_alu[`SRL];
    wire alu_sra = e_i_alu[`SRA];
    wire alu_eq = e_i_alu[`EQ];
    wire alu_neq = e_i_alu[`NEQ];
    wire alu_ge = e_i_alu[`GE];
    wire alu_geu = e_i_alu[`GEU];
    wire opcode_rtype = e_i_opcode[`RTYPE];
    wire opcode_itype = e_i_opcode[`ITYPE];
    wire opcode_load_wore = e_i_opcode[`LOAD_WORD];
    wire opcode_store_wore = e_i_opcode[`STORE_WORD];
    wire opcode_branch = e_i_opcode[`BRANCH];
    wire opcode_jal = e_i_opcode[`JAL];
    wire opcode_jalr = e_i_opcode[`JALR];
    wire opcode_lui = e_i_opcode[`LUI];
    wire opcode_auipc = e_i_opcode[`AUIPC];
    wire opcode_system = e_i_opcode[`SYSTEM];
    wire opcode_fence = e_i_opcode[`FENCE];
endmodule
`endif 