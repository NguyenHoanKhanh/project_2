`ifndef DECODER_V
`define DECODER_V
`include "./source/header.vh"

module decoder #(
    parameter DWIDTH = 32,
    parameter IWIDTH = 32,
    parameter AWIDTH = 5,
    parameter PC_WIDTH = 32,
    parameter FUNCT_WIDTH = 3
)(
    d_clk, d_rst, d_i_instr, d_i_pc, d_o_pc, d_o_addr_rs1, d_o_addr_rs1_p, d_o_addr_rs2, d_o_addr_rs2_p, 
    d_o_addr_rd, d_o_addr_rd_p, d_o_imm, d_o_funct3, d_o_alu, d_o_opcode, d_o_exception, d_i_ce, d_o_ce, 
    d_i_stall, d_o_stall, d_i_flush, d_o_flush
);
    input d_clk, d_rst;
    input [IWIDTH - 1 : 0] d_i_instr;
    input [PC_WIDTH - 1 : 0] d_i_pc;
    output reg [PC_WIDTH - 1 : 0] d_o_pc;
    // d_o_addr_rx is used for testbench's output and d_o_addr_rx_p is use for pipeline's output
    output [AWIDTH - 1 : 0] d_o_addr_rs1;
    output [AWIDTH - 1 : 0] d_o_addr_rs2;
    output reg [AWIDTH - 1 : 0] d_o_addr_rs1_p;
    output reg [AWIDTH - 1 : 0] d_o_addr_rs2_p;
    output [AWIDTH - 1 : 0] d_o_addr_rd;
    output reg [AWIDTH - 1 : 0] d_o_addr_rd_p;
    output reg [FUNCT_WIDTH - 1 : 0] d_o_funct3;
    output reg [DWIDTH - 1 : 0] d_o_imm;
    output reg [`ALU_WIDTH - 1 : 0] d_o_alu;
    output reg [`OPCODE_WIDTH - 1 : 0] d_o_opcode;
    output reg [`EXCEPTION_WIDTH - 1 : 0] d_o_exception;
    input d_i_ce;
    output reg d_o_ce;
    input d_i_stall;
    output d_o_stall;
    input d_i_flush;
    output d_o_flush;

    reg [AWIDTH - 1 : 0] temp_addr_rs2, temp_addr_rs1, temp_addr_rd;
    assign d_o_addr_rs2 = temp_addr_rs2;
    assign d_o_addr_rs1 = temp_addr_rs1;
    assign d_o_addr_rd = temp_addr_rd;
    reg [FUNCT_WIDTH - 1 : 0] funct3;
    reg [6 : 0] opcode;

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
    reg alu_lt_d;
    reg alu_ltu_d;
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

    reg valid_opcode;
    reg illegal_check;
    wire [11 : 0] system_exception = d_i_instr[31 : 20];
    wire stall_bit = d_o_stall || d_i_stall;
    assign d_o_stall = d_i_stall || (d_o_exception[`ILLEGAL] && d_o_ce);
    assign d_o_flush = d_i_flush || d_o_exception[`ECALL];

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            d_o_ce <= 0;
            d_o_pc <= {PC_WIDTH{1'b0}};
            valid_opcode <= 1'b0;
            illegal_check <= 1'b0;
            d_o_addr_rs1_p <= {AWIDTH{1'b0}};
            d_o_addr_rs2_p <= {AWIDTH{1'b0}};
            d_o_addr_rd_p <= {AWIDTH{1'b0}};
            d_o_exception <= {`EXCEPTION_WIDTH{1'b0}};
            d_o_alu <= {`ALU_WIDTH{1'b0}};
            d_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            temp_addr_rs2 <= {AWIDTH{1'b0}};
            temp_addr_rs1 <= {AWIDTH{1'b0}};
            temp_addr_rd <= {AWIDTH{1'b0}};
        end
        else begin
            if (d_i_ce && !stall_bit) begin
                d_o_pc <= d_i_pc;
                d_o_addr_rs1_p <= temp_addr_rs1;
                d_o_addr_rs2_p <= temp_addr_rs2;
                d_o_addr_rd_p <= temp_addr_rd;
                d_o_funct3 <= funct3;
                d_o_imm <= imm_d;
                
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
            if (d_i_ce && !stall_bit) begin
                d_o_exception[`ILLEGAL] <= !valid_opcode || illegal_check;  
                if (opcode_system_d && funct3 == 3'b000) begin
                    d_o_exception[`ECALL] <= (system_exception == 12'h000);
                    d_o_exception[`EBREAK] <= (system_exception == 12'h001);
                    d_o_exception[`MRET] <= (system_exception == 12'h302);
                end
                else begin
                    d_o_exception[`ECALL] <= 1'b0;
                    d_o_exception[`EBREAK] <= 1'b0;
                    d_o_exception[`MRET] <= 1'b0;
                end
            end
            else begin
                illegal_check <= 1'b0;
                d_o_exception <= {`EXCEPTION_WIDTH{1'b0}};
            end
            //Anytime, if this stage receive flush or stall signal, Signal o_ce will not be turn on
            //Concurrently, this stage will be postponed
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

    always@ (*)begin
        temp_addr_rs1 = {AWIDTH{1'b0}};
        temp_addr_rs2 = {AWIDTH{1'b0}};
        temp_addr_rd  = {AWIDTH{1'b0}};
        opcode = d_i_instr[6 : 0];
        funct3 = {FUNCT_WIDTH{1'b0}};
        imm_d = {DWIDTH{1'b0}};
        illegal_check = 0;

        alu_add_d = 0;
        alu_sub_d = 0;
        alu_slt_d = 0;
        alu_sltu_d = 0;
        alu_xor_d = 0;
        alu_or_d = 0;
        alu_and_d = 0;
        alu_sll_d = 0;
        alu_srl_d = 0;
        alu_sra_d = 0;
        alu_eq_d = 0;
        alu_neq_d = 0;
        alu_lt_d = 0;
        alu_ltu_d = 0;
        alu_ge_d = 0;
        alu_geu_d = 0;
        
        opcode_rtype_d = opcode == `OPCODE_RTYPE;
        opcode_itype_d = opcode == `OPCODE_ITYPE;
        opcode_load_word_d = opcode == `OPCODE_LOAD;
        opcode_store_word_d = opcode == `OPCODE_STORE;
        opcode_branch_d = opcode == `OPCODE_BRANCH;
        opcode_jal_d = opcode == `OPCODE_JAL;
        opcode_jalr_d = opcode == `OPCODE_JALR; 
        opcode_lui_d = opcode == `OPCODE_LUI;
        opcode_auipc_d = opcode == `OPCODE_AUIPC;
        opcode_system_d = opcode == `OPCODE_SYSTEM; 
        opcode_fence_d = opcode == `OPCODE_FENCE; 

        // d_o_opcode <= opcode;            
        valid_opcode = (opcode_rtype_d || opcode_itype_d || opcode_load_word_d || opcode_store_word_d || opcode_branch_d || opcode_jal_d || 
        opcode_jalr_d || opcode_lui_d || opcode_auipc_d || opcode_system_d || opcode_fence_d);

        //Calculating exception
        //Check illegal signal 
        if (opcode_itype_d) begin
            illegal_check = (alu_sll_d || alu_srl_d || alu_sra_d) && d_i_instr[25] != 0;
        end
        else if (opcode_rtype_d) begin
            if (!((funct3 == `FUNCT3_ADD && (d_i_instr[30] == 0 || d_i_instr[30] == 1)) || 
                (funct3 == `FUNCT3_SLT) || (funct3 == `FUNCT3_SLTU) || (funct3 == `FUNCT3_XOR) || 
                (funct3 == `FUNCT3_OR) || (funct3 == `FUNCT3_AND) || (funct3 == `FUNCT3_SLL) ||
                (funct3 == `FUNCT3_SRA && (d_i_instr[30] == 0 || d_i_instr[30] == 1)))) begin
                illegal_check = 1;
                // $display($time, " Illegal R-type funct3=%b, funct7[30]=%b for instr=%h", funct3, d_i_instr[30], d_i_instr);
            end
        end
        else if (opcode_load_word_d) begin
            if (!(funct3 == `FUNCT_LB || funct3 == `FUNCT_LH || funct3 == `FUNCT_LW || 
                funct3 == `FUNCT_LBU || funct3 == `FUNCT_LHU)) begin
                illegal_check = 1;
                // $display($time, " Illegal LOAD funct3=%b for instr=%h", funct3, d_i_instr);
            end
        end
        else if (opcode_store_word_d) begin
            if (!(funct3 == `FUNCT_SB || funct3 == `FUNCT_SW || funct3 == `FUNCT_SH)) begin
                illegal_check = 1;
                // $display($time, " Illegal STORE funct3=%b for instr=%h", funct3, d_i_instr);
            end
        end
        else if (opcode_branch_d) begin
            if (!(funct3 == `FUNCT3_EQ  || funct3 == `FUNCT3_NEQ ||
                funct3 == `FUNCT3_LT  || funct3 == `FUNCT3_GE  ||
                funct3 == `FUNCT3_LTU || funct3 == `FUNCT3_GEU)) begin
                illegal_check = 1;
            end
        end
        else if (opcode_fence_d) begin
            illegal_check = !((d_i_instr[14 : 12] == 3'b000) || (d_i_instr[14 : 12] == 3'b001));
        end
                
        if (opcode_rtype_d) begin
            temp_addr_rs2 = d_i_instr[24 : 20];
            temp_addr_rs1 = d_i_instr[19 : 15];
            temp_addr_rd = d_i_instr[11 : 7];
            funct3 = d_i_instr[14 : 12];
        end
        else if (opcode_itype_d || opcode_load_word_d || opcode_jalr_d || opcode_system_d || 
            opcode_fence_d) begin
            temp_addr_rs2 = {AWIDTH{1'b0}};
            temp_addr_rs1 = d_i_instr[19 : 15];
            temp_addr_rd = d_i_instr[11 : 7];
            funct3 = d_i_instr[14 : 12];
        end
        else if (opcode_store_word_d || opcode_branch_d) begin
            temp_addr_rs2 = d_i_instr[24 : 20];
            temp_addr_rs1 = d_i_instr[19 : 15];
            temp_addr_rd = {AWIDTH{1'b0}};
            funct3 = d_i_instr[14 : 12];
        end
        else if (opcode_lui_d || opcode_auipc_d || opcode_jal_d) begin
            temp_addr_rs2 = {AWIDTH{1'b0}};
            temp_addr_rs1 = {AWIDTH{1'b0}};
            temp_addr_rd = d_i_instr[11 : 7];
            funct3 = {FUNCT_WIDTH{1'b0}};
        end
        else begin
            temp_addr_rs2 = {AWIDTH{1'b0}};
            temp_addr_rs1 = {AWIDTH{1'b0}};
            temp_addr_rd = {AWIDTH{1'b0}};
            funct3 = {FUNCT_WIDTH{1'b0}};
            illegal_check = 1;
            // $display($time, " Illegal opcode=%b for instr=%h", opcode, d_i_instr);
        end

        case (opcode)
            `OPCODE_RTYPE : begin
                imm_d = {32{1'b0}};
            end
            `OPCODE_ITYPE, `OPCODE_JALR, `OPCODE_LOAD : begin
                imm_d = {{20{d_i_instr[31]}}, d_i_instr[31 : 20]};
            end
            `OPCODE_STORE : begin
                imm_d = {{20{d_i_instr[31]}}, d_i_instr[31 : 25], d_i_instr[11 : 7]};
            end
            `OPCODE_BRANCH : begin
                imm_d = {{20{d_i_instr[31]}}, d_i_instr[7], d_i_instr[30 : 25], d_i_instr[11 : 8], 1'b0};
            end
            `OPCODE_JAL : begin
                imm_d = {{12{d_i_instr[31]}}, d_i_instr[19 : 12], d_i_instr[20], d_i_instr[30 : 21], 1'b0};
            end
            `OPCODE_LUI, `OPCODE_AUIPC : begin
                imm_d = {d_i_instr[31 : 12], {12{1'b0}}};
            end
            `OPCODE_SYSTEM, `OPCODE_FENCE : begin
                imm_d = {{20{1'b0}}, d_i_instr[31 : 20]};
            end
            default : begin
                imm_d = {32{1'b0}}; 
                illegal_check = 1;
                // $display($time, " Default case: Illegal opcode=%b for instr=%h", opcode, d_i_instr);
            end
        endcase

        if (opcode == `OPCODE_RTYPE || opcode == `OPCODE_ITYPE) begin
            if (opcode == `OPCODE_RTYPE) begin
                if (funct3 == `FUNCT3_ADD) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_ZERO) begin
                        alu_add_d = 1;
                    end
                    else if (d_i_instr[31 : 25] == `FUNCT7_SUB) begin
                        alu_sub_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_SLL) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_SLL) begin
                        alu_sll_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_SLT) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_SLT) begin
                        alu_slt_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_SLTU) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_SLTU) begin
                        alu_sltu_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_XOR) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_XOR) begin
                        alu_xor_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_OR) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_OR) begin
                        alu_or_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_AND) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_AND) begin
                        alu_and_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else if (funct3 == `FUNCT3_SRA) begin
                    if (d_i_instr[31 : 25] == `FUNCT7_SRL) begin
                        alu_srl_d = 1;
                    end
                    else if (d_i_instr[31 : 25] == `FUNCT7_SRA) begin
                        alu_sra_d = 1;
                    end
                    else begin
                        illegal_check = 1;
                    end
                end
                else begin
                    illegal_check = 1; // Funct3 không hợp lệ cho R-type
                    // $display($time, " Illegal R-type funct3=%b, funct7[30]=%b for instr=%h", funct3, d_i_instr[30], d_i_instr);
                end
            end
            else begin
                alu_add_d = (funct3 == `FUNCT3_ADD);
                alu_slt_d = (funct3 == `FUNCT3_SLT);
                alu_sltu_d = (funct3 == `FUNCT3_SLTU);
                alu_xor_d = (funct3 == `FUNCT3_XOR);
                alu_or_d = (funct3 == `FUNCT3_OR);
                alu_and_d = (funct3 == `FUNCT3_AND);
                alu_sll_d = (funct3 == `FUNCT3_SLL && d_i_instr[31 : 25] == `FUNCT7_SLL);
                alu_srl_d = (funct3 == `FUNCT3_SRA && d_i_instr[31 : 25] == `FUNCT7_SRL);
                alu_sra_d = (funct3 == `FUNCT3_SRA && d_i_instr[31 : 25] == `FUNCT7_SRA);
                if (!(funct3 == `FUNCT3_ADD || funct3 == `FUNCT3_SLT || funct3 == `FUNCT3_SLTU || 
                    funct3 == `FUNCT3_XOR || funct3 == `FUNCT3_OR || funct3 == `FUNCT3_AND || 
                    funct3 == `FUNCT3_SLL || funct3 == `FUNCT3_SRA)) begin
                    illegal_check = 1;
                    // $display($time, " Illegal I-type funct3=%b for instr=%h", funct3, d_i_instr);
                end
            end
        end
        else if (opcode == `OPCODE_BRANCH) begin
            alu_eq_d = (funct3 ==`FUNCT3_EQ);
            alu_neq_d = (funct3 == `FUNCT3_NEQ);
            alu_lt_d = (funct3 == `FUNCT3_LT);
            alu_ltu_d = (funct3 == `FUNCT3_LTU);
            alu_ge_d = (funct3 == `FUNCT3_GE);
            alu_geu_d = (funct3 == `FUNCT3_GEU);
            if (!(funct3 == `FUNCT3_EQ  || funct3 == `FUNCT3_NEQ ||
                funct3 == `FUNCT3_LT  || funct3 == `FUNCT3_GE  ||
                funct3 == `FUNCT3_LTU || funct3 == `FUNCT3_GEU)) begin
                illegal_check = 1;
            end
        end
        else begin
            alu_add_d = 1;
        end
    end
endmodule
`endif 