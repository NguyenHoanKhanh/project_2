`ifndef MEMORY_STAGE_V
`define MEMORY_STAGE_V
`include "./source/header.vh"
`include "./source/memory.v"

module mem_stage #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3
)(
    me_o_opcode, me_i_opcode, me_o_load_addr, me_o_store_data, me_o_store_addr, me_o_we, 
    me_o_stb, me_o_cyc, me_i_rs2_data, me_i_alu_value, me_o_flush, me_i_flush, me_o_stall, me_i_stall, 
    me_o_ce, me_i_ce, me_rst, me_clk, me_i_rd_data, me_i_rd_addr, 
    me_o_rd_addr, me_o_rd_data, me_o_rd_we, me_i_funct3
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
    wire [DWIDTH - 1 : 0] me_i_load_data; 
    wire me_i_ack;

    input [AWIDTH - 1 : 0] me_i_rd_addr;
    input [DWIDTH - 1 : 0] me_i_rd_data;
    output reg [AWIDTH - 1 : 0] me_o_rd_addr;
    output reg [DWIDTH - 1 : 0] me_o_rd_data;
    output reg me_o_rd_we;

    input [2 : 0] me_i_funct3;
    wire [1 : 0] byte_offset = me_i_alu_value[1 : 0];
    reg [3 : 0] byte_enable;

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) m (
        .m_clk(me_clk), 
        .m_rst(me_rst), 
        .m_i_cyc(me_o_cyc), 
        .m_i_stb(me_o_stb), 
        .m_i_we(me_o_we), 
        .m_i_be_enable(byte_enable),
        .m_i_load_addr(me_o_load_addr), 
        .m_i_store_addr(me_o_store_addr), 
        .m_i_data(me_o_store_data), 
        .m_o_read_data(me_i_load_data), 
        .m_o_ack(me_i_ack), 
        .m_o_stall(me_i_stall)
    );

    wire stall_bit = me_i_stall || me_o_stall;
    reg pending_request;
    reg rd_we_d;
    reg [DWIDTH - 1 : 0] rd_data_d;
    reg [AWIDTH - 1 : 0] rd_addr_d;
    reg [DWIDTH - 1 : 0 ] store_data_aligned;
    wire [DWIDTH - 1 : 0] raw = me_i_load_data >> (byte_offset * 8);

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
            rd_we_d <= 1'b0;
            me_o_rd_data <= {DWIDTH{1'b0}};
            rd_data_d <= {DWIDTH{1'b0}};
            me_o_rd_addr <= {AWIDTH{1'b0}};
            rd_addr_d <= {AWIDTH{1'b0}};
        end
        else begin
            if (!me_i_flush && me_i_ack) begin
                if (me_i_ce || !stall_bit) begin
                    me_o_opcode <= me_i_opcode;
                    me_o_rd_addr <= rd_addr_d;
                    me_o_rd_we <= rd_we_d;
                    me_o_rd_data <= rd_data_d;
                end
                rd_we_d <= 1'b0;
                me_o_we <= 1'b0;
                me_o_stb <= 1'b0;
                me_o_cyc <= 1'b0;
                me_o_ce <= 1'b0;
                byte_enable <= 4'b0000;
                store_data_aligned <= {DWIDTH{1'b0}};
                pending_request <= 1'b0;
            end
            if (me_i_ce && !pending_request && (me_i_opcode == `LOAD || me_i_opcode == `STORE)) begin
                pending_request <= 1'b1;
            end
            if (me_i_flush) begin
                me_o_flush <= 1'b1;
                me_o_ce <= 1'b0;
                pending_request <= 1'b0;
            end
            else if (!stall_bit) begin
                me_o_ce <= me_i_ce;
                me_o_flush <= 1'b0;
            end
            else begin
                me_o_ce <= 1'b0;
            end
        end
    end

    always @(*) begin
        me_o_we = 1'b0;
        me_o_cyc = 1'b0;
        me_o_stb = 1'b0;
        me_o_stall = 1'b0;
        if (me_i_ce && !pending_request) begin
            if (me_i_opcode == `LOAD) begin
                me_o_we = 1'b0;
                me_o_cyc = 1'b1;
                me_o_stb = 1'b1;
            end
            else if (me_i_opcode == `STORE) begin
                me_o_we = 1'b1;
                me_o_cyc = 1'b1;
                me_o_stb = 1'b1;
            end
            else if (me_i_opcode == `RTYPE || me_i_opcode == `ITYPE || me_i_opcode == `JAL || 
                    me_i_opcode == `JALR || me_i_opcode == `LUI || me_i_opcode == `AUIPC) begin
                rd_we_d = 1'b1;
            end
        end
        if (pending_request && !me_i_ack) begin
            me_o_stall = 1'b1;
        end
    end     

    always @(*) begin
        case (me_i_funct3)
            `FUNCT_SB : begin 
                store_data_aligned = {4{me_i_rs2_data[7 : 0]}} << (byte_offset * 8);
            end 
            `FUNCT_SH : begin
                store_data_aligned = {2{me_i_rs2_data[15 : 0]}} << (byte_offset * 8);
            end
            `FUNCT_SW : begin
                store_data_aligned = me_i_rs2_data;
            end
            default : begin
                store_data_aligned = {DWIDTH{1'b0}};
            end 
        endcase
    end

    always @(*) begin
        me_o_load_addr = {AWIDTH{1'b0}};
        me_o_store_addr = {AWIDTH{1'b0}};
        me_o_store_data = {DWIDTH{1'b0}};
        rd_addr_d = {AWIDTH{1'b0}};
        rd_data_d = {DWIDTH{1'b0}};
        case (me_i_opcode)
            `LOAD : begin
                me_o_opcode = me_i_opcode;
                me_o_load_addr = me_i_alu_value;
                rd_data_d = final_load;
            end
            `STORE : begin
                me_o_opcode = me_i_opcode;
                me_o_store_addr = me_i_alu_value;
                me_o_store_data = store_data_aligned;
            end
            `RTYPE, `ITYPE, `JAL, `JALR, `LUI, `AUIPC : begin
                rd_addr_d = me_i_rd_addr;
                rd_data_d = me_i_alu_value;
            end
            default : begin
                me_o_load_addr = {AWIDTH{1'b0}};
                me_o_store_addr = {AWIDTH{1'b0}};
                me_o_store_data = {DWIDTH{1'b0}};
            end
        endcase
    end

    always @(*) begin
        case (me_i_funct3)
            `FUNCT_SB : begin
                byte_enable = 4'b0001 << byte_offset;
            end
            `FUNCT_SH : begin
                byte_enable = (byte_offset[0] == 0) ? 4'b0011 << (byte_offset & 2'b10) : 4'b1100;
            end
            `FUNCT_SW : begin
                byte_enable = 4'b1111;
            end
            default : begin
                byte_enable = 4'b0000;
            end 
        endcase
    end

    reg [DWIDTH - 1 : 0] final_load;
    always @(*) begin
        case (me_i_funct3)
            `FUNCT_LB : begin
                final_load = {{24{raw[7]}}, raw[7 : 0]};
            end
            `FUNCT_LH : begin
                final_load = {{16{raw[15]}}, raw[15 : 0]};
            end
            `FUNCT_LW : begin
                final_load = raw;
            end
            `FUNCT_LBU : begin
                final_load = {24'b0, raw[7 : 0]};
            end
            `FUNCT_LHU : begin
                final_load = {16'b0, raw[15 : 0]};
            end
            default : final_load = {DWIDTH{1'b0}}; 
        endcase
    end
endmodule
`endif 