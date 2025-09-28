`ifndef CONTROL_MEM_V
`define CONTROL_MEM_V
`include "./source/header.vh"
module control_mem (
    clk, rst_n, me_i_ce, temp_pending_request, me_o_we, me_o_rd, me_o_cyc, me_o_stb, rd_we_d, me_i_opcode
);
    input clk, rst_n;
    input me_i_ce;
    input temp_pending_request;
    input [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    output reg me_o_we, me_o_rd, me_o_cyc, me_o_stb, rd_we_d;
    wire op_store = me_i_opcode[`STORE_WORD];
    wire op_load = me_i_opcode[`LOAD_WORD];
    wire op_rtype = me_i_opcode[`RTYPE];
    wire op_itype = me_i_opcode[`ITYPE];
    wire op_jal = me_i_opcode[`JAL];
    wire op_jalr = me_i_opcode[`JALR];
    wire op_lui = me_i_opcode[`LUI];
    wire op_auipc = me_i_opcode[`AUIPC];
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            me_o_we <= 1'b0;
            me_o_rd <= 1'b0;
            me_o_cyc <= 1'b0;
            me_o_stb <= 1'b0;
            rd_we_d <= 1'b0;
        end
        else begin
            if (me_i_ce && !temp_pending_request) begin
                if (op_store) begin
                    me_o_we <= 1'b1;
                    me_o_cyc <= 1'b1;
                    me_o_stb <= 1'b1;
                end
                else if (op_load) begin
                    me_o_rd <= 1'b1;
                    me_o_cyc <= 1'b1;
                    me_o_stb <= 1'b1;
                end
                else if (op_rtype || op_itype || op_jal || op_jalr || op_lui || op_auipc) begin
                    rd_we_d <= 1'b1;
                end
            end
        end
    end    
endmodule
`endif 