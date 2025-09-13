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
    fe_clk, fe_rst, fe_i_ce, fe_i_stall, fe_i_flush,
    fe_o_alu, fe_o_opcode, fe_o_addr_rd, fe_o_data_rd,
    fe_o_funct3, fe_o_imm, fe_next_pc, fe_pc_n, fe_alu_value,
    fe_o_stall_n, fe_o_flush_n, fe_o_ce_n, fe_stall_alu,
    fe_o_ce, fe_o_data_rs1, fe_o_data_rs2, fe_o_addr_rs1, fe_o_addr_rs2,
    fe_o_valid, fe_we_reg
);
    input  fe_clk, fe_rst;
    input  fe_i_ce;
    input  fe_i_stall;
    input  fe_i_flush;

    // ---------- Wires giữa CONNECT và EXECUTE ----------
    wire [`OPCODE_WIDTH-1:0] fe_i_opcode;
    wire [`ALU_WIDTH-1:0]    fe_i_alu;
    wire [DWIDTH-1:0]        fe_i_imm;
    wire [FUNCT_WIDTH-1:0]   fe_i_funct3;

    wire [IWIDTH-1:0]        fe_i_instr_fetch;
    wire [PC_WIDTH-1:0]      fe_pc;         // PC hiện tại từ fetch/decoder
    wire [AWIDTH-1:0]        fe_i_addr_rs1;
    wire [AWIDTH-1:0]        fe_i_addr_rs2;
    wire [AWIDTH-1:0]        fe_i_addr_rd;
    wire [DWIDTH-1:0]        fe_i_data_rs1;
    wire [DWIDTH-1:0]        fe_i_data_rs2;

    wire                      fe_o_stall;
    wire                      fe_o_flush;
    output                    fe_o_ce;      // từ decoder_stage (enable xuống EX)
    output                    fe_we_reg;    // tín hiệu ghi RF (từ EX)

    // ---------- Outputs tổng hợp/hiển thị ----------
    output [`ALU_WIDTH-1:0]   fe_o_alu;
    output [`OPCODE_WIDTH-1:0]fe_o_opcode;
    output [AWIDTH-1:0]       fe_o_addr_rd;
    output [DWIDTH-1:0]       fe_o_data_rd;   // WB data ra ngoài (debug/quan sát)
    output [FUNCT_WIDTH-1:0]  fe_o_funct3;
    output [DWIDTH-1:0]       fe_o_imm;
    output [PC_WIDTH-1:0]     fe_pc_n;        // PC copy ở EX (debug)
    output [PC_WIDTH-1:0]     fe_next_pc;     // PC đích từ EX (redirect)
    output [DWIDTH-1:0]       fe_alu_value;
    output                    fe_o_stall_n, fe_o_flush_n, fe_o_ce_n; // debug EX
    output                    fe_stall_alu;

    output [DWIDTH-1:0]       fe_o_data_rs1;
    output [DWIDTH-1:0]       fe_o_data_rs2;
    output [AWIDTH-1:0]       fe_o_addr_rs1;
    output [AWIDTH-1:0]       fe_o_addr_rs2;
    output                    fe_o_valid;

    // ---------- Wires trực tiếp từ EX ----------
    wire [DWIDTH-1:0] ex_data_rd;       // ex_o_data_rd
    wire              ex_change_pc;     // ex_o_change_pc

    // ===================== CONNECT (Fetch + Decoder + RF) =====================
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

        // upstream control
        .fi_i_stall(fe_i_stall),
        .fi_i_flush(fe_i_flush),
        .fi_i_ce   (fe_i_ce),

        // fetch out
        .fi_o_instr_fetch(fe_i_instr_fetch),

        // register file read ports
        .ds_data_out_rs1(fe_i_data_rs1),
        .ds_data_out_rs2(fe_i_data_rs2),

        // register file writeback (drive trực tiếp từ EX)
        .ds_data_in_rd(ex_data_rd),
        .ds_we        (fe_we_reg),

        // decoder outputs (control to EX)
        .ds_o_opcode   (fe_i_opcode),
        .ds_o_alu      (fe_i_alu),
        .ds_o_imm      (fe_i_imm),
        .ds_o_funct3   (fe_i_funct3),
        .ds_o_addr_rd_p(fe_i_addr_rd),
        .ds_o_addr_rs1_p(fe_i_addr_rs1),
        .ds_o_addr_rs2_p(fe_i_addr_rs2),

        // handshakes
        .ds_o_ce    (fe_o_ce),
        .ds_o_stall (fe_o_stall),
        .ds_o_flush (fe_o_flush),

        // current PC from decoder
        .ds_o_pc    (fe_pc)
    );

    // ============================== EXECUTE ==================================
    execute #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) e (
        .ex_clk        (fe_clk),
        .ex_rst        (fe_rst),

        // control từ decoder
        .ex_i_alu      (fe_i_alu),
        .ex_i_opcode   (fe_i_opcode),

        // pass-through control (debug)
        .ex_o_alu      (fe_o_alu),
        .ex_o_opcode   (fe_o_opcode),

        // địa chỉ/giá trị thanh ghi
        .ex_i_addr_rs1 (fe_i_addr_rs1),
        .ex_o_addr_rs1 (fe_o_addr_rs1),
        .ex_i_addr_rs2 (fe_i_addr_rs2),
        .ex_o_addr_rs2 (fe_o_addr_rs2),
        .ex_i_addr_rd  (fe_i_addr_rd),

        .ex_i_data_rs1 (fe_i_data_rs1),
        .ex_o_data_rs1 (fe_o_data_rs1),
        .ex_i_data_rs2 (fe_i_data_rs2),
        .ex_o_data_rs2 (fe_o_data_rs2),

        // dữ liệu ghi về RF
        .ex_o_data_rd  (ex_data_rd),    // <-- WIRE trực tiếp
        // (xuất ra top cho debug)
        // fe_o_data_rd: assign riêng phía dưới

        // funct3/imm/pc
        .ex_i_funct3   (fe_i_funct3),
        .ex_o_funct3   (fe_o_funct3),
        .ex_i_imm      (fe_i_imm),
        .ex_o_imm      (fe_o_imm),

        // enable/stall/flush giữa DS->EX
        .ex_i_ce       (fe_o_ce),
        .ex_o_ce       (fe_o_ce_n),
        .ex_i_stall    (fe_o_stall),
        .ex_o_stall    (fe_o_stall_n),
        .ex_i_flush    (fe_o_flush),
        .ex_o_flush    (fe_o_flush_n),

        // PC in/out + redirect
        .ex_i_pc       (fe_pc),
        .ex_o_pc       (fe_pc_n),
        .ex_next_pc    (fe_next_pc),
        .ex_o_change_pc(ex_change_pc),

        // trạng thái ghi/valid
        .ex_o_we_reg   (fe_we_reg),
        .ex_o_valid    (fe_o_valid),

        // debug
        .ex_stall_from_alu(fe_stall_alu),
        .ex_o_alu_value (fe_alu_value),
        .ex_o_addr_rd   (fe_o_addr_rd)
    );

    // Xuất dữ liệu ghi RD ra ngoài để tiện quan sát (không cần lưu lại 1 chu kỳ)
    assign fe_o_data_rd = ex_data_rd;

endmodule
`endif
