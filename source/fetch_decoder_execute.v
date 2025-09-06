`ifndef FETCH_DECODER_EXECUTE_V
`define FETCH_DECODER_EXECUTE_V
`include "./source/connect_fet_de.v"
`include "./source/execute_stage.v"

module fetch_execute #(
    parameter IWIDTH = 32,
    parameter DEPTH = 36,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3,
    parameter DWIDTH = 32
)(
    fe_clk, fe_rst, fe_i_ce, fe_i_stall, fe_i_flush, fe_o_alu, fe_o_opcode, fe_o_addr_rd, fe_o_data_rd, 
    fe_o_funct3, fe_o_imm, fe_next_pc, fe_pc_n, fe_alu_value, fe_o_stall_n, fe_o_flush_n, fe_o_ce_n, fe_stall_alu,
    fe_o_ce, fe_o_data_rs1, fe_o_data_rs2, fe_o_addr_rs1, fe_o_addr_rs2, fe_o_valid, fe_we_reg
);
    input fe_clk, fe_rst;
    //Control
    input fe_i_ce;
    wire [`OPCODE_WIDTH - 1 : 0] fe_i_opcode;
    wire [`ALU_WIDTH - 1 : 0] fe_i_alu;
    wire [DWIDTH - 1 : 0] fe_i_imm;
    wire [FUNCT_WIDTH - 1 : 0] fe_i_funct3;

    output fe_o_ce;
    wire fe_change_pc;
    output fe_we_reg;
    reg temp_we;
    //Value
    wire [IWIDTH - 1 : 0] fe_i_instr_fetch;
    wire [PC_WIDTH - 1 : 0] fe_pc;
    wire [AWIDTH - 1 : 0] fe_i_addr_rs1;
    wire [DWIDTH - 1 : 0] fe_i_data_rs1;
    output [AWIDTH - 1 : 0] fe_o_addr_rs1;
    output [DWIDTH - 1 : 0] fe_o_data_rs1;
    wire [AWIDTH - 1 : 0] fe_i_addr_rs2;
    output [AWIDTH - 1 : 0] fe_o_addr_rs2;
    output [DWIDTH - 1 : 0] fe_o_data_rs2;
    wire [DWIDTH - 1 : 0] fe_i_data_rs2;
    wire [AWIDTH - 1 : 0] fe_i_addr_rd;
    output fe_o_valid;
    //Stall - flush
    input fe_i_stall;
    wire fe_o_stall;
    input fe_i_flush;
    wire fe_o_flush;
    //Output 
    output [`ALU_WIDTH - 1 : 0] fe_o_alu;
    output [`OPCODE_WIDTH - 1 : 0] fe_o_opcode;
    output [AWIDTH - 1 : 0] fe_o_addr_rd;
    output reg [DWIDTH - 1 : 0] fe_o_data_rd;
    output [FUNCT_WIDTH - 1 : 0] fe_o_funct3;
    output [DWIDTH - 1 : 0] fe_o_imm;
    output [PC_WIDTH - 1 : 0] fe_pc_n, fe_next_pc;
    output [DWIDTH - 1 : 0] fe_alu_value;
    output fe_o_stall_n, fe_o_flush_n, fe_o_ce_n;
    output fe_stall_alu;
    integer i;
    reg [AWIDTH - 1 : 0] temp_addr_rd;
    wire [DWIDTH - 1 : 0] temp_data_rd;
    reg temp_ce;

    connect #(
        .IWIDTH(IWIDTH),
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .DEPTH(DEPTH)
    ) c (
        .c_clk(fe_clk), 
        .c_rst(fe_rst), 
        .fi_i_stall(fe_i_stall), 
        .fi_i_flush(fe_i_flush), 
        .fi_i_ce(fe_i_ce), 
        .fi_o_instr_fetch(fe_i_instr_fetch), 
        .ds_data_out_rs1(fe_i_data_rs1),
        .ds_data_out_rs2(fe_i_data_rs2),
        .ds_data_in_rd(fe_o_data_rd), 
        .ds_o_opcode(fe_i_opcode), 
        .ds_o_alu(fe_i_alu), 
        .ds_o_imm(fe_i_imm), 
        .ds_o_funct3(fe_i_funct3), 
        .ds_o_addr_rd_p(fe_i_addr_rd), 
        .ds_o_addr_rs1_p(fe_i_addr_rs1), 
        .ds_o_addr_rs2_p(fe_i_addr_rs2),
        .ds_we(temp_we), 
        .ds_o_ce(fe_o_ce),  
        .ds_o_stall(fe_o_stall), 
        .ds_o_flush(fe_o_flush), 
        .ds_o_pc(fe_pc)
    );

    execute #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) e (
        .ex_clk(fe_clk), 
        .ex_rst(fe_rst), 
        .ex_i_alu(fe_i_alu), 
        .ex_i_opcode(fe_i_opcode), 
        .ex_o_alu(fe_o_alu), 
        .ex_o_opcode(fe_o_opcode), 
        .ex_i_addr_rs1(fe_i_addr_rs1),
        .ex_o_addr_rs1(fe_o_addr_rs1),
        .ex_i_addr_rs2(fe_i_addr_rs2),
        .ex_o_addr_rs2(fe_o_addr_rs2),
        .ex_i_addr_rd(temp_addr_rd), 
        .ex_i_data_rs1(fe_i_data_rs1), 
        .ex_o_data_rs1(fe_o_data_rs1),
        .ex_i_data_rs2(fe_i_data_rs2), 
        .ex_o_data_rs2(fe_o_data_rs2),
        .ex_o_data_rd(temp_data_rd), 
        .ex_i_funct3(fe_i_funct3), 
        .ex_o_funct3(fe_o_funct3), 
        .ex_i_imm(fe_i_imm), 
        .ex_o_imm(fe_o_imm), 
        .ex_i_ce(temp_ce), 
        .ex_o_ce(fe_o_ce_n), 
        .ex_i_stall(fe_o_stall), 
        .ex_o_stall(fe_o_stall_n), 
        .ex_i_flush(fe_o_flush), 
        .ex_o_flush(fe_o_flush_n), 
        .ex_i_pc(fe_pc), 
        .ex_o_pc(fe_pc_n), 
        .ex_next_pc(fe_next_pc), 
        .ex_o_change_pc(fe_change_pc),
        .ex_o_we_reg(fe_we_reg), 
        .ex_o_valid(fe_o_valid), 
        .ex_stall_from_alu(fe_stall_alu), 
        .ex_o_alu_value(fe_alu_value), 
        .ex_o_addr_rd(fe_o_addr_rd)
    );

    always @(posedge fe_clk or negedge fe_rst) begin
        if (!fe_rst) begin
            temp_we <= 1'b0;
            temp_ce <= 1'b0;
            temp_addr_rd <= {AWIDTH{1'b0}};
            fe_o_data_rd <= {DWIDTH{1'b0}};
        end
        else begin
            temp_ce <= fe_o_ce;
            if (temp_ce && !fe_o_flush && !fe_o_stall) begin
                temp_we <= fe_we_reg;
                temp_addr_rd <= fe_i_addr_rd;
                if (temp_we && fe_o_valid) begin
                    fe_o_data_rd <= temp_data_rd;
                end
            end
        end
    end

endmodule
`endif 