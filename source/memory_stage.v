`ifndef MEMORY_STAGE_V
`define MEMORY_STAGE_V
`include "./source/header.vh"
`include "./source/memory.v"

module mem_stage #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3
)(
    me_o_opcode, me_i_opcode, me_i_ack, me_o_load_addr, me_o_store_data, me_o_store_addr, me_o_we, 
    me_o_stb, me_o_cyc, me_i_rs2_data, me_i_alu_value, me_o_flush, me_i_flush,
    me_o_stall, me_i_stall, me_o_ce, me_i_ce, me_rst, me_clk, me_o_load_data, me_i_load_data,
    me_i_rd_data, me_i_rd_addr, me_o_rd_addr, me_o_rd_data, me_o_rd_we
);
    input me_clk;
    input me_rst;
    input me_i_ce;
    output reg me_o_ce;
    input me_i_stall;
    output reg me_o_stall;
    input me_i_flush;
    output reg me_o_flush;

    input [DWIDTH - 1 : 0] me_i_alu_value;
    input [DWIDTH - 1 : 0] me_i_rs2_data;
    input [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    output reg [`OPCODE_WIDTH - 1 : 0] me_o_opcode;
    output reg me_o_cyc;
    output reg me_o_stb;
    output reg me_o_we;
    output reg [AWIDTH - 1 : 0] me_o_store_addr;
    output reg [DWIDTH - 1 : 0] me_o_store_data;
    output reg [AWIDTH - 1 : 0] me_o_load_addr;
    input [DWIDTH - 1 : 0] me_i_load_data;
    output [DWIDTH - 1 : 0] me_o_load_data;
    input me_i_ack;

    input [AWIDTH - 1 : 0] me_i_rd_addr;
    input [DWIDTH - 1 : 0] me_i_rd_data;
    output reg [AWIDTH - 1 : 0] me_o_rd_addr;
    output reg [DWIDTH - 1 : 0] me_o_rd_data;
    output reg me_o_rd_we;

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) m (
        .m_clk(me_clk), 
        .m_rst(me_rst), 
        .m_i_cyc(me_o_cyc), 
        .m_i_stb(me_o_stb), 
        .m_i_we(me_o_we), 
        .m_i_load_addr(me_o_load_addr), 
        .m_i_store_addr(me_o_store_addr), 
        .m_i_data(me_o_store_data), 
        .m_o_read_data(me_i_load_data), 
        .m_o_ack(me_i_ack), 
        .m_o_stall(me_i_stall)
    );

    wire stall_bit = me_i_stall || me_o_stall;
    assign me_o_load_data = me_i_load_data;
    reg pending_request;

    always @(posedge me_clk, negedge me_rst) begin
        if (!me_rst) begin
            me_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            me_o_load_addr <= {AWIDTH{1'b0}};
            me_o_store_addr <= {AWIDTH{1'b0}};
            me_o_store_data <= {DWIDTH{1'b0}};
            me_o_we <= 1'b0;
            me_o_stb <= 1'b0;
            me_o_cyc <= 1'b0;
            me_o_flush <= 1'b0;
            me_o_stall <= 1'b0;
            me_o_ce <= 1'b0;
            pending_request <= 1'b0;
            me_o_rd_we <= 1'b0;
            me_o_rd_data <= {DWIDTH{1'b0}};
            me_o_rd_addr <= {AWIDTH{1'b0}};
            pending_request <= 1'b0;
        end
        else begin
            if (!me_i_flush && me_i_ack) begin
                if (me_i_ce || !stall_bit) begin
                    me_o_opcode <= me_i_opcode;
                    me_o_rd_addr <= {AWIDTH{1'b0}};
                    me_o_rd_we <= 1'b0;
                    me_o_rd_data <= {DWIDTH{1'b0}};
                end
            end
            if (me_i_flush && !me_i_stall) begin
                me_o_flush <= 1'b1;
            end
            if (me_i_ack) begin
                pending_request <= 1'b0;
            end
            else if (me_i_ce && !pending_request && (me_i_opcode == `LOAD_WORD || me_i_opcode == `STORE_WORD)) begin
                pending_request <= 1'b1;
            end
        end
    end

    always @(*) begin
        me_o_ce = 1'b0;
        if (me_i_flush || !stall_bit) begin
            me_o_ce = 1'b0;
        end
        else if (!stall_bit) begin
            me_o_ce <= me_i_ce;
        end
        else if (stall_bit && !me_i_stall) begin
            me_o_ce <= 1'b0;
        end
    end

    always @(*) begin
        me_o_we = 1'b0;
        me_o_rd_we = 1'b0;
        me_o_cyc = 1'b0;
        me_o_stb = 1'b0;
        me_o_stall = 1'b0;
        if (me_i_ce && !pending_request) begin
            if (me_i_opcode == `LOAD_WORD) begin
                me_o_we <= 1'b0;
                me_o_cyc <= 1'b1;
                me_o_stb <= 1'b1;
            end
            else if (me_i_opcode == `STORE_WORD) begin
                me_o_we <= 1'b1;
                me_o_cyc <= 1'b1;
                me_o_stb <= 1'b1;
            end
            else if (me_i_opcode == `RTYPE || me_i_opcode == `ITYPE || me_i_opcode == `JAL || 
                    me_i_opcode == `JALR || me_i_opcode == `LUI || me_i_opcode == `AUIPC) begin
                me_o_rd_we <= 1'b1;
            end
        end
        if (pending_request && !me_i_ack) begin
            me_o_stall = 1'b1;
        end
    end

    always @(*) begin
        me_o_load_addr = {AWIDTH{1'b0}};
        me_o_store_addr = {AWIDTH{1'b0}};
        me_o_store_data = {DWIDTH{1'b0}};
        me_o_rd_addr = {AWIDTH{1'b0}};
        me_o_rd_data = {DWIDTH{1'b0}};
        case (me_i_opcode)
            `LOAD_WORD : begin
                me_o_load_addr = me_i_alu_value;
            end
            `STORE_WORD : begin
                me_o_store_addr = me_i_alu_value;
                me_o_store_data = me_i_rs2_data;
            end
            `RTYPE, `ITYPE, `JAL, `JALR, `LUI, `AUIPC : begin
                me_o_rd_addr = me_i_rd_addr;
                me_o_rd_data = me_i_rd_data;
            end
            default : begin
                me_o_load_addr = {AWIDTH{1'b0}};
                me_o_store_addr = {AWIDTH{1'b0}};
                me_o_store_data = {DWIDTH{1'b0}};
            end
        endcase
    end
endmodule
`endif 