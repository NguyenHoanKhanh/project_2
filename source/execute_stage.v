`ifndef EXECUTE_STAGE_V
`define EXECUTE_STAGE_V
`include "./source/header.vh"

module execute #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter PC_WIDTH = 32
)(
    e_clk, e_rst, e_i_alu, e_i_addr_rs1, e_o_addr_rs1, e_i_rs1, e_o_rs1, e_i_rs2, e_o_rs2, e_i_imm, e_o_imm, e_i_funct3, e_o_funct3, e_i_opcode, e_o_opcode, e_i_exception, e_o_exception, e_o_result_alu, e_i_pc, e_o_pc, e_o_next_pc, e_o_change_pc, e_o_we, e_o_read_valid, e_i_addr_rd, e_o_addr_rd, e_o_data_rd, e_o_stall_from_alu, e_i_ce, e_o_ce, e_i_stall, e_o_stall, e_i_flush, e_o_flush, e_i_force_stall
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
    output reg [11 : 0] e_o_imm;
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
    output reg [AWIDTH - 1 : 0] e_o_addr_rd;
    output reg [DWIDTH - 1 : 0] e_o_data_rd;
    //Pipeline control
    output reg e_o_stall_from_alu;
    input e_i_ce;
    output reg e_o_ce;
    input e_i_stall;
    output reg e_o_stall;
    input e_i_flush;
    output reg e_o_flush;
    input e_i_force_stall;

    //Initial operand
    reg [DWIDTH - 1 : 0] a, b;
    reg [DWIDTH - 1 : 0] alu_result;
    reg [DWIDTH - 1 : 0] wb_result;
    reg e_o_we_d;
    reg e_o_read_valid_d;
    reg [PC_WIDTH - 1 : 0] pc;
    wire [PC_WIDTH - 1 : 0] sum;
    wire stall_bit = e_o_stall || e_i_stall;

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

    always @(posedge e_clk, negedge e_rst) begin
        if (!e_rst) begin
            e_o_exception <= 0;
            e_o_ce <= 0;
            e_o_stall_from_alu <= 0;
        end
        else begin
            if (e_i_ce && !stall_bit) begin
                e_o_opcode <= e_i_opcode;
                e_o_exception <= e_i_exception;
                e_o_result_alu <= alu_result;
                e_o_addr_rs1 <= e_o_addr_rs1;
                e_o_rs1 <= e_i_rs1;
                e_o_rs2 <= e_i_rs2;
                e_o_addr_rd <= e_i_addr_rd;
                e_o_imm <= e_i_imm[11 : 0];
                e_o_funct3 <= e_i_funct3;
                e_o_data_rd <= wb_result;
                e_o_read_valid <= e_o_read_valid_d;
                e_o_we <= e_o_we_d;
                e_o_stall_from_alu <= e_i_opcode[`STORE_WORD] || e_i_opcode[`LOAD_WORD];
                e_o_pc <= e_i_pc;
            end
            if (e_i_flush && !stall_bit) begin
                e_o_ce <= 0;
            end
            else if (!stall_bit) begin
                e_o_ce <= e_i_ce;
            end
            else if (stall_bit && !e_i_stall) begin
                e_o_ce <= 0;
            end
        end
    end

    always @(*) begin
        alu_result = 0;
        a = (opcode_jal || opcode_auipc) ? e_i_pc : e_i_rs1;
        b = (opcode_rtype || opcode_branch) ? e_i_rs2 : e_i_imm;
        if (alu_add) begin
            alu_result = a + b;
        end
        if (alu_sub) begin
            alu_result = a - b;
        end
        if (alu_slt) begin
            if (a[31] ^ b[31]) begin
                alu_result = {31'b0, a[31]};
            end
            else begin
                alu_result = {31'b0, ($signed(a) < $signed(b))};
            end
        end
        if (alu_sltu) begin
            alu_result = {31'b0, (a < b)};
        end
        if (alu_xor) begin
            alu_result = a ^ b;
        end
        if (alu_or) begin
            alu_result = a | b;
        end
        if (alu_and) begin
            alu_result = a & b;
        end
        if (alu_sll) begin
            alu_result = a << b[4 : 0];
        end
        if (alu_srl) begin
            alu_result = a >> b[4 : 0];
        end
        if (alu_sra) begin
            alu_result = $signed(a) >>> b[4 : 0];
        end
        if (alu_eq) begin
            alu_result = {31'b0, (a == b)}; 
        end
        if (alu_neq) begin
            alu_result = {31'b0, !alu_result[0]};
        end
        if (alu_geu) begin
            alu_result = {31'b0, (a >= b)};
        end
        if (alu_ge) begin
            if (a[31] ^ b[31]) begin
                alu_result = {31'b0, a[31]};
            end
            else begin
                alu_result = {31'b0, ($signed(a) >= $signed(b))};
            end
        end
    end
endmodule
`endif 