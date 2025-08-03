`ifndef EXECUTE_STAGE_V
`define EXECUTE_STAGE_V
`include "./source/header.vh"
module execute #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter FUNCT_WIDTH = 3,
    parameter PC_WIDTH = 32
)(
    ex_clk, ex_rst, ex_i_alu, ex_i_opcode, ex_o_alu, ex_o_opcode, ex_i_addr_rs1, 
    ex_i_addr_rs2, ex_i_addr_rd, ex_i_data_rs1, ex_i_data_rs2, ex_o_data_rd, 
    ex_i_funct3, ex_o_funct3, ex_i_imm, ex_o_imm, ex_i_ce, ex_o_ce, ex_i_stall, 
    ex_o_stall, ex_i_flush, ex_o_flush, ex_i_pc, ex_o_pc, ex_next_pc, ex_o_change_pc,
    ex_o_we, ex_o_valid, ex_stall_from_alu
);
    input ex_clk, ex_rst;
    // ALU control
    input [`ALU_WIDTH - 1 : 0] ex_i_alu;
    output reg [`ALU_WIDTH - 1 : 0] ex_o_alu;
    wire alu_add = (ex_i_alu == `ADD) ? 1 : 0;
    wire alu_sub = (ex_i_alu == `SUB) ? 1 : 0;
    wire alu_slt = (ex_i_alu == `SLT) ? 1 : 0;
    wire alu_sltu = (ex_i_alu == `SLTU) ? 1 : 0;
    wire alu_xor = (ex_i_alu == `XOR) ? 1 : 0;
    wire alu_or = (ex_i_alu == `OR) ? 1 : 0;
    wire alu_and = (ex_i_alu == `AND) ? 1 : 0;
    wire alu_sll = (ex_i_alu == `SLL) ? 1 : 0;
    wire alu_srl = (ex_i_alu == `SRL) ? 1 : 0;
    wire alu_sra = (ex_i_alu == `SRA) ? 1 : 0;
    wire alu_eq = (ex_i_alu == `EQ) ? 1 : 0;
    wire alu_neq = (ex_i_alu == `NEQ) ? 1 : 0;
    wire alu_ge = (ex_i_alu == `GE) ? 1 : 0;
    wire alu_geu = (ex_i_alu == `GEU) ? 1 : 0;

    // OPCODE control
    input [`OPCODE_WIDTH - 1 : 0] ex_i_opcode;
    output reg [`OPCODE_WIDTH - 1 : 0] ex_o_opcode;
    wire op_rtype = (ex_i_opcode == `RTYPE) ? 1 : 0;
    wire op_itype = (ex_i_opcode == `ITYPE) ? 1 : 0;
    wire op_load = (ex_i_opcode == `LOAD_WORD) ? 1 : 0;
    wire op_store = (ex_i_opcode == `STORE_WORD) ? 1 : 0;
    wire op_branch = (ex_i_opcode == `BRANCH) ? 1 : 0;
    wire op_jal = (ex_i_opcode == `JAL) ? 1 : 0;
    wire op_jalr = (ex_i_opcode == `JALR) ? 1 : 0;
    wire op_lui = (ex_i_opcode == `LUI) ? 1 : 0;
    wire op_auipc = (ex_i_opcode == `AUIPC) ? 1 : 0;
    wire op_system = (ex_i_opcode == `SYSTEM) ? 1 : 0;
    wire op_fence = (ex_i_opcode == `FENCE) ? 1 : 0;

    //Register rs1, rs2, rd
    input [AWIDTH - 1 : 0] ex_i_addr_rs1;
    output reg [AWIDTH - 1 : 0] ex_o_addr_rs1;
    input [AWIDTH - 1 : 0] ex_i_addr_rs2;
    output reg [AWIDTH - 1 : 0] ex_o_addr_rs2;
    input [AWIDTH - 1 : 0] ex_i_addr_rd;
    input [DWIDTH - 1 : 0] ex_i_data_rs1;
    output reg [DWIDTH - 1 : 0] ex_o_data_rs1;
    input [DWIDTH - 1 : 0] ex_i_data_rs2;
    output reg [DWIDTH - 1 : 0] ex_o_data_rs2;
    output reg [AWIDTH - 1 : 0] ex_o_addr_rd;
    output reg [DWIDTH - 1 : 0] ex_o_data_rd;
    output reg ex_o_valid;

    //PC
    input [PC_WIDTH - 1 : 0] ex_i_pc;
    output reg [PC_WIDTH - 1 : 0] ex_o_pc;
    output reg [PC_WIDTH - 1 : 0] ex_next_pc;
    output reg ex_o_change_pc;

    //The remaining components
    input [FUNCT_WIDTH - 1 : 0] ex_i_funct3;
    output reg [FUNCT_WIDTH - 1 : 0] ex_o_funct3;
    input [DWIDTH - 1 : 0] ex_i_imm;
    output reg [11 : 0] ex_o_imm;
    output reg ex_o_we;
    
    //Enable, stall, flush pipeline
    input ex_i_ce;
    output reg ex_o_ce;
    input ex_i_stall;
    output reg ex_o_stall;
    input ex_i_flush;
    output reg ex_o_flush;
    output reg ex_stall_from_alu;

    //Temporary variables
    reg [DWIDTH - 1 : 0] alu_value;
    wire [PC_WIDTH - 1 : 0] temp_pc;
    assign temp_pc = ex_i_pc;
    reg [DWIDTH - 1 : 0] a, b;
    wire [4 : 0] shamt = b[4 : 0];
    wire stall_bit = ex_i_stall || ex_o_stall;

    always @(posedge ex_clk, negedge ex_rst) begin
        if (!ex_rst) begin
            ex_stall_from_alu <= 1'b0;
            ex_o_flush <= 1'b0;
            ex_o_stall <= 1'b0;
            ex_o_we <= 1'b0;
            ex_o_imm <= 12'b0;
            ex_o_funct3 <= {FUNCT_WIDTH{1'b0}};
            ex_next_pc <= {PC_WIDTH{1'b0}};
            ex_o_change_pc <= 1'b0;
            ex_o_pc <= {PC_WIDTH{1'b0}};
            ex_o_valid <= 1'b0;
            ex_o_data_rd <= {DWIDTH{1'b0}};
            ex_o_addr_rd <= {AWIDTH{1'b0}};
            ex_o_data_rs2 <= {DWIDTH{1'b0}};
            ex_o_data_rs1 <= {DWIDTH{1'b0}};
            ex_o_addr_rs2 <= {AWIDTH{1'b0}};
            ex_o_addr_rs1 <= {AWIDTH{1'b0}};
            ex_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            ex_o_alu <= {`ALU_WIDTH{1'b0}};
        end
        else begin
            ex_next_pc        <= temp_pc;
            ex_o_pc           <= temp_pc;
            ex_o_addr_rd      <= ex_i_addr_rd;     
            if (!ex_i_flush) begin
                if (ex_i_ce && !stall_bit) begin
                    ex_o_alu <= ex_i_alu;
                    ex_o_opcode <= ex_i_opcode;
                    ex_o_funct3 <= ex_i_funct3;
                    ex_o_addr_rs1 <= ex_i_addr_rs1;
                    ex_o_addr_rs2 <= ex_i_addr_rs2;
                    ex_o_data_rs1 <= ex_i_data_rs1;
                    ex_o_data_rs2 <= ex_i_data_rs2;
                    ex_o_imm <= ex_i_imm[11 : 0];
                    ex_stall_from_alu <= (op_load || op_store) ? 1 : 0;
                end
                if (op_rtype || op_itype) begin
                    ex_o_data_rd <= alu_value;
                end
                else if (op_branch && alu_value[0]) begin
                    ex_next_pc <= temp_pc + ex_i_imm;
                    ex_o_change_pc <= ex_i_ce;
                    ex_o_flush <= ex_i_ce;
                end
                else if (op_jal) begin
                    ex_next_pc <= temp_pc + ex_i_imm;
                    ex_o_change_pc <= ex_i_ce;
                    ex_o_flush <= ex_i_ce;
                    ex_o_we <= 1'b1;
                    ex_o_data_rd <= temp_pc + 4;
                    ex_o_valid <= 1'b1;
                end
                else if (op_jalr) begin
                    ex_next_pc <= ex_i_data_rs1 + ex_i_imm;
                    ex_o_change_pc <= ex_i_ce;
                    ex_o_flush <= ex_i_ce;
                    ex_o_we <= 1'b1;
                    ex_o_data_rd <= temp_pc + 4;
                    ex_o_valid <= 1'b1;
                end
                if (op_lui) begin
                    ex_o_change_pc <= 1'b0;
                    ex_o_flush <= 1'b0;
                    ex_o_we <= 1'b1;
                    ex_o_data_rd <= ex_i_imm[31 : 12] << 12;
                    ex_o_valid <= 1'b1;
                end
                else if (op_auipc) begin
                    ex_o_change_pc <= 1'b0;
                    ex_o_flush <= 1'b0;
                    ex_o_we <= 1'b1;
                    ex_o_data_rd <= ex_i_pc + ex_i_imm;
                    ex_o_valid <= 1'b1;
                end
            end
        end
    end

    always @(*) begin
        ex_o_ce = 0;
        if (ex_i_flush && !stall_bit) begin
            ex_o_ce = 0;
        end
        else if (!stall_bit) begin
            ex_o_ce = ex_i_ce;
        end
        else if (stall_bit && !ex_i_stall) begin
            ex_o_ce = 0;
        end
    end

    always @(*) begin
        a = (op_jal || op_auipc) ? ex_i_pc : op_lui ? {DWIDTH{1'b0}} : ex_i_data_rs1;
        b = (op_rtype || op_branch) ? ex_i_data_rs2 : ex_i_imm;

        case (1'b1)
            alu_add : begin
                alu_value = a + b;
            end
            alu_sub : begin
                alu_value = a - b;
            end
            alu_slt : begin
                if ($signed (a) < $signed(b)) begin
                    alu_value = {31'b0, 1'b1};
                end
                else begin
                    alu_value = 32'b0;
                end
            end
            alu_sltu : begin
                if ($unsigned (a) < $unsigned(b)) begin
                    alu_value = {31'b0, 1'b1};
                end
                else begin
                    alu_value = 32'b0;
                end
            end
            alu_xor : begin
                alu_value = a ^ b;
            end
            alu_or : begin
                alu_value = a | b;
            end
            alu_and : begin
                alu_value = a & b;
            end
            alu_sll : begin
                alu_value = a << shamt;
            end
            alu_srl : begin
                alu_value = a >> shamt;
            end
            alu_sra : begin
                alu_value = $signed(a) >>> shamt;
            end
            alu_eq : begin
                alu_value = (a == b) ? 32'd1 : 32'd0;
            end
            alu_neq : begin
                alu_value = (a == b) ? 32'd0 : 32'd1;
            end
            alu_ge : begin
                if ($signed (a) >= $signed(b)) begin
                    alu_value = {31'b0, 1'b1};
                end
                else begin
                    alu_value = 32'b0;
                end
            end
            alu_geu : begin
                if ($unsigned (a) >= $unsigned(b)) begin
                    alu_value = {31'b0, 1'b1};
                end
                else begin
                    alu_value = 32'b0;
                end
            end
            default : alu_value = {DWIDTH{1'b0}};
        endcase
    end
endmodule
`endif 