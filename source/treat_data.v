`ifndef TREAT_DATA_V
`define TREAT_DATA_V
`include "./source/header.vh"

module treat_data #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32
)(
    me_o_load_addr, me_o_store_addr, me_o_store_data, rd_addr_d, rd_data_d, me_i_ce, temp_pending_request, me_i_opcode,
    mem_addr, store_data_aligned, me_i_rd_addr, me_i_alu_value, clk, rst_n
);
    input clk, rst_n;
    input me_i_ce;
    input temp_pending_request;
    input [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    input [AWIDTH - 1 : 0] mem_addr;
    input [DWIDTH - 1 : 0] store_data_aligned;
    input [AWIDTH - 1 : 0] me_i_rd_addr;
    input [DWIDTH - 1 : 0] me_i_alu_value;
    output reg [AWIDTH - 1 : 0] me_o_load_addr, me_o_store_addr, rd_addr_d;
    output reg [DWIDTH - 1 : 0] me_o_store_data, rd_data_d;

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
            me_o_load_addr <= {AWIDTH{1'b0}};
            me_o_store_addr <= {AWIDTH{1'b0}};
            me_o_store_data <= {DWIDTH{1'b0}};
            rd_addr_d <= {AWIDTH{1'b0}};
            rd_data_d <= {DWIDTH{1'b0}};
        end
        else begin
            if(me_i_ce && !temp_pending_request && op_load) begin
                me_o_load_addr <= mem_addr;
            end
            else if(me_i_ce && !temp_pending_request && op_store) begin
                me_o_store_addr <= mem_addr;
                me_o_store_data <= store_data_aligned;
            end
            else if(op_rtype || op_itype || op_jal || op_jalr || op_lui || op_auipc) begin
                rd_addr_d <= me_i_rd_addr;
                rd_data_d <= me_i_alu_value;
            end
            else begin
                me_o_load_addr <= {AWIDTH{1'b0}};
                me_o_store_addr <= {AWIDTH{1'b0}};
                me_o_store_data <= {DWIDTH{1'b0}};
                rd_addr_d <= {AWIDTH{1'b0}};
                rd_data_d <= {DWIDTH{1'b0}};
            end
        end
    end
endmodule
`endif 