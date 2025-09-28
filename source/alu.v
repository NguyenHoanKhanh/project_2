`ifndef ALU_V
`define ALU_V
`include "./source/header.vh"

module alu #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter PC_WIDTH = 32
)(
    ex_o_we_reg, ex_i_addr_rd, ex_i_addr_rs1, ex_i_addr_rs2, ex_i_data_rs1, ex_i_data_rs2, temp_data_rd,
    ex_i_opcode, ex_i_pc, ex_i_imm, alu_value, ex_i_alu, clk, rst_n
);
    input clk, rst_n;
    input ex_o_we_reg;
    input [AWIDTH - 1 : 0] ex_i_addr_rd;
    input [AWIDTH - 1 : 0] ex_i_addr_rs1, ex_i_addr_rs2;
    input [DWIDTH - 1 : 0] ex_i_data_rs1, ex_i_data_rs2;
    input [DWIDTH - 1 : 0] temp_data_rd;
    input [PC_WIDTH - 1 : 0] ex_i_pc;
    input [DWIDTH - 1 : 0] ex_i_imm;
    output reg [DWIDTH - 1 : 0] alu_value;
    wire [DWIDTH - 1 : 0] a, b;
//Forwarding value avoids using old data when writeback occurs in the same cycle as decoder/execute read
    wire [DWIDTH - 1 : 0] rs1_value = (ex_o_we_reg && (ex_i_addr_rd == ex_i_addr_rs1)) ? temp_data_rd : ex_i_data_rs1;
    wire [DWIDTH - 1 : 0] rs2_value = (ex_o_we_reg && (ex_i_addr_rd == ex_i_addr_rs2)) ? temp_data_rd : ex_i_data_rs2;
    wire [4 : 0] shamt = b[4 : 0];
    input [`OPCODE_WIDTH - 1 : 0] ex_i_opcode;
    wire op_rtype = ex_i_opcode[`RTYPE];
    wire op_itype = ex_i_opcode[`ITYPE];
    wire op_load = ex_i_opcode[`LOAD_WORD];
    wire op_store = ex_i_opcode[`STORE_WORD];
    wire op_branch = ex_i_opcode[`BRANCH];
    wire op_jal = ex_i_opcode[`JAL];
    wire op_jalr = ex_i_opcode[`JALR];
    wire op_lui = ex_i_opcode[`LUI];
    wire op_auipc = ex_i_opcode[`AUIPC];
    wire op_system = ex_i_opcode[`SYSTEM];
    wire op_fence = ex_i_opcode[`FENCE];

    input [`ALU_WIDTH - 1 : 0] ex_i_alu;
    wire alu_add = ex_i_alu[`ADD];
    wire alu_sub = ex_i_alu[`SUB];
    wire alu_slt = ex_i_alu[`SLT];
    wire alu_sltu = ex_i_alu[`SLTU];
    wire alu_xor = ex_i_alu[`XOR];
    wire alu_or = ex_i_alu[`OR];
    wire alu_and = ex_i_alu[`AND];
    wire alu_sll = ex_i_alu[`SLL];
    wire alu_srl = ex_i_alu[`SRL];
    wire alu_sra = ex_i_alu[`SRA];
    wire alu_eq = ex_i_alu[`EQ];
    wire alu_neq = ex_i_alu[`NEQ];
    wire alu_ge = ex_i_alu[`GE];
    wire alu_geu = ex_i_alu[`GEU];

    assign a = (op_jal || op_auipc) ? ex_i_pc : op_lui ? {DWIDTH{1'b0}} : rs1_value;
    assign b = (op_rtype || op_branch) ? rs2_value : ex_i_imm;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            alu_value <= {DWIDTH{1'b0}};
        end
        else begin
            if (alu_add) begin
                alu_value <= a + b;
            end
            else if (alu_sub) begin
                alu_value <= a - b;
            end
            else if (alu_slt) begin
                if ($signed (a) < $signed(b)) begin
                    alu_value <= {31'b0, 1'b1};
                end
                else begin
                    alu_value <= 32'b0;
                end
            end
            else if (alu_sltu) begin
                if ($unsigned (a) < $unsigned(b)) begin
                    alu_value <= {31'b0, 1'b1};
                end
                else begin
                    alu_value <= 32'b0;
                end
            end
            else if (alu_xor) begin
                alu_value <= a ^ b;
            end
            else if (alu_or) begin
                alu_value <= a | b;
            end
            else if (alu_and) begin
                alu_value <= a & b;
            end
            else if (alu_sll) begin
                alu_value <= a << shamt;
            end
            else if (alu_srl) begin
                alu_value <= a >> shamt;
            end
            else if (alu_sra) begin
                alu_value <= $signed(a) >>> shamt;
            end
            else if (alu_eq) begin
                alu_value <= (a == b) ? 32'd1 : 32'd0;
            end
            else if (alu_neq) begin
                alu_value <= (a == b) ? 32'd0 : 32'd1;
            end
            else if (alu_ge) begin
                if ($signed (a) >= $signed(b)) begin
                    alu_value <= {31'b0, 1'b1};
                end
                else begin
                    alu_value <= 32'b0;
                end
            end
            else if (alu_geu) begin
                if ($unsigned (a) >= $unsigned(b)) begin
                    alu_value <= {31'b0, 1'b1};
                end
                else begin
                    alu_value <= 32'b0;
                end
            end
        end
    end
endmodule
`endif