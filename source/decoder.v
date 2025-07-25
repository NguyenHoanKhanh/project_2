`ifndef DECODER_V
`define DECODER_V
`include "./source/header.vh"

module decoder #(
    parameter DWIDTH = 32,
    parameter IWIDTH = 32,
    parameter AWIDTH = 5,
    parameter DEPTH = 1 << AWIDTH,
    parameter PC_WIDTH = 32
)(
    d_clk, d_rst, d_i_instr, d_i_pc, d_o_pc, d_o_addr_rs1, d_o_addr_rs1_p, d_o_addr_rs2, d_o_addr_rs2_p, d_o_addr_rd, d_o_addr_rd_p, d_o_imm, d_o_funct3, d_o_alu, d_o_opcode, d_o_exception, d_i_ce, d_o_ce, d_i_stall, d_o_stall, d_i_flush, d_o_flush
);
    input d_clk, d_rst;
    input [IWIDTH - 1 : 0] d_i_instr;
    input [PC_WIDTH - 1 : 0] d_i_pc;
    output reg [PC_WIDTH - 1 : 0] d_o_pc;
    output [AWIDTH - 1 : 0] d_o_addr_rs1, d_o_addr_rs2;
    output reg [AWIDTH - 1 : 0] d_o_addr_rs1_p, d_o_addr_rs2_p;
    output [AWIDTH - 1 : 0] d_o_addr_rd;
    output reg [AWIDTH - 1 : 0] d_o_addr_rd_p;
    output reg [2 : 0] d_o_funct3;
    output reg [DWIDTH - 1 : 0] d_o_imm;
    output reg [`ALU_WIDTH - 1 : 0] d_o_alu;
    output reg [`OPCODE_WIDTH - 1 : 0] d_o_opcode;
    output reg [`EXCEPTION_WIDTH - 1 : 0] d_o_exception;
    input d_i_ce;
    output reg d_o_ce;
    input d_i_stall;
    output reg d_o_stall;
    input d_i_flush;
    output reg d_o_flush;

    assign d_o_addr_rs1 = d_i_instr[19 : 15];
    assign d_o_addr_rd = d_i_instr[11 : 7];
    wire [2 : 0] funct = d_i_instr[14 : 12];
    wire [6 : 0] opcode = d_i_instr[6 : 0];

    reg [31 : 0] imm_d;
    reg alu_add_d;
    reg alu_sub_d;
    reg alu_slt_d;
    reg alu_sltu_d;
    reg alu_xor_d;
    reg alu_or_d;
    reg alu_and_d;
    reg alu_sll_d;
    reg alu_srl_d;
    reg alu_sra_d;
    reg alu_eq_d;
    reg alu_neq_d;
    reg alu_ge_d;
    reg alu_geu_d;

    reg opcode_rtype_d;
    reg opcode_itype_d;
    reg opcode_load_word_d;
    reg opcode_store_word_d;
    reg opcode_branch_d;
    reg opcode_jal_d;
    reg opcode_jalr_d;
    reg opcode_lui_d;
    reg opcode_auipc_d;
    reg opcode_system_d;
    reg opcode_fence_d;

    wire stall_bit = d_o_stall || d_i_stall;

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            d_o_ce <= 0;
        end
        else begin
            if (d_o_ce && !stall_bit) begin
                d_o_pc <= d_i_pc;
                d_o_addr_rs1_p <= d_o_addr_rs1_p;
                d_o_addr_rd_p <= d_o_addr_rd;
                d_o_funct3 <= funct;
                d_o_opcode <= opcode;

                d_o_alu[`ADD] <= alu_add_d;
                d_o_alu[`SUB] <= alu_sub_d;
                d_o_alu[`SLT] <= alu_slt_d;
                d_o_alu[`SLTU] <= alu_sltu_d;
                d_o_alu[`XOR] <= alu_xor_d;
                d_o_alu[`OR] <= alu_or_d;
                d_o_alu[`AND] <= alu_and_d;
                d_o_alu[`SLL] <= alu_sll_d;
                d_o_alu[`SRL] <= alu_srl_d;
                d_o_alu[`SRA] <= alu_sra_d;
                d_o_alu[`EQ] <= alu_eq_d;
                d_o_alu[`NEQ] <= alu_neq_d;
                d_o_alu[`GE] <= alu_ge_d;
                d_o_alu[`GEU] <= alu_geu_d;

                d_o_opcode[`RTYPE] <= opcode_rtype_d;
                d_o_opcode[`ITYPE] <= opcode_itype_d;
                d_o_opcode[`LOAD_WORD] <= opcode_load_word_d;
                d_o_opcode[`STORE_WORD] <= opcode_store_word_d;
                d_o_opcode[`BRANCH] <= opcode_branch_d;
                d_o_opcode[`JAL] <= opcode_jal_d;
                d_o_opcode[`JALR] <= opcode_jalr_d;
                d_o_opcode[`LUI] <= opcode_lui_d;
                d_o_opcode[`AUIPC] <= opcode_auipc_d;
                d_o_opcode[`SYSTEM] <= opcode_system_d;
                d_o_opcode[`FENCE] <= opcode_fence_d;
            end
            if (d_i_flush && !stall_bit) begin
                d_o_ce <= 0;
            end
            else if (!stall_bit) begin
                d_o_ce <= d_i_ce;
            end
            else if (stall_bit && !d_i_stall) begin
                d_o_ce <= 0;
            end
        end
    end
endmodule

`endif 