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
    me_o_ce, me_i_ce, me_rst, me_clk, me_i_rd_data, me_i_rd_addr, me_o_funct3,
    me_o_rd_addr, me_o_rd_data, me_o_rd_we, me_i_funct3, me_o_load_data, me_o_rd
);
    input me_clk;
    input me_rst;
    input me_i_ce;
    output reg me_o_ce;
    input me_i_stall;
    output reg me_o_stall;
    input me_i_flush;
    output reg me_o_flush;
    wire m_i_stall;

    input [DWIDTH - 1 : 0] me_i_alu_value;
    input [DWIDTH - 1 : 0] me_i_rs2_data;
    input [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    output reg [`OPCODE_WIDTH - 1 : 0] me_o_opcode;
    output reg me_o_cyc;
    output reg me_o_stb;
    output reg me_o_we;
    output reg me_o_rd;
    output reg [AWIDTH - 1 : 0] me_o_store_addr;
    output reg [DWIDTH - 1 : 0] me_o_store_data;
    output reg [AWIDTH - 1 : 0] me_o_load_addr;
    output reg [DWIDTH - 1 : 0] me_o_load_data;
    wire [DWIDTH - 1 : 0] me_i_load_data; 
    wire me_i_ack;

    input [AWIDTH - 1 : 0] me_i_rd_addr;
    input [DWIDTH - 1 : 0] me_i_rd_data;
    output reg [AWIDTH - 1 : 0] me_o_rd_addr;
    output reg [DWIDTH - 1 : 0] me_o_rd_data;
    output reg me_o_rd_we;

    input [FUNCT_WIDTH - 1 : 0] me_i_funct3;
    output reg [FUNCT_WIDTH - 1 : 0] me_o_funct3;
    wire [1 : 0] byte_offset = me_i_alu_value[1 : 0];
    reg [3 : 0] byte_enable;

    wire [AWIDTH - 1 : 0] mem_addr;

    assign mem_addr = me_i_alu_value >> 2;

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) m (
        .m_clk(me_clk), 
        .m_rst(me_rst), 
        .m_i_cyc(me_o_cyc), 
        .m_i_stb(me_o_stb), 
        .m_i_we(me_o_we),
        .m_i_rd(me_o_rd),
        .m_o_stall(m_i_stall),
        .m_i_byte_enable(byte_enable),
        .m_i_load_addr(me_o_load_addr), 
        .m_i_store_addr(me_o_store_addr), 
        .m_i_data_store(me_o_store_data), 
        .m_o_read_data(me_i_load_data), 
        .m_o_ack(me_i_ack)
    );

    wire stall_bit = me_i_stall || me_o_stall || m_i_stall;
    reg pending_request;
    // pipeline/commit registers (unchanged semantics)
    reg rd_we_d;
    reg [DWIDTH - 1 : 0] rd_data_d;
    reg [AWIDTH - 1 : 0] rd_addr_d;
    reg [DWIDTH - 1 : 0 ] store_data_aligned;
    reg [DWIDTH - 1 : 0] me_o_load_data_d;
    reg [FUNCT_WIDTH - 1 : 0] funct_d;
    
    reg [1 : 0] byte_offset_d;
    reg [3 : 0] byte_enable_d;
    reg [DWIDTH - 1 : 0] store_data_aligned_d;

    always @(posedge me_clk, negedge me_rst) begin
        if (!me_rst) begin
            // Initial output signal
            me_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            me_o_ce <= 1'b0;
            me_o_stall <= 1'b0;
            me_o_flush <= 1'b0;
            me_o_cyc <= 1'b0;
            me_o_stb <= 1'b0;
            me_o_we <= 1'b0;
            me_o_rd <= 1'b0;
            me_o_store_addr <= {AWIDTH{1'b0}};
            me_o_store_data <= {DWIDTH{1'b0}};
            me_o_load_addr <= {AWIDTH{1'b0}};
            me_o_load_data <= {DWIDTH{1'b0}};
            me_o_rd_addr <= {AWIDTH{1'b0}};
            me_o_rd_data <= {DWIDTH{1'b0}};
            me_o_rd_we <= 1'b0;
            me_o_funct3 <= {FUNCT_WIDTH{1'b0}};

            //Initial internal signal
            pending_request <= 1'b0;
            rd_we_d <= 1'b0;
            rd_addr_d <= {AWIDTH{1'b0}};
            rd_data_d <= {DWIDTH{1'b0}};
            me_o_load_data_d <= {DWIDTH{1'b0}};
            funct_d <= {FUNCT_WIDTH{1'b0}};
            store_data_aligned <= {DWIDTH{1'b0}};
            byte_enable <= 4'b0000;
        end
        else begin
            me_o_stall <= (pending_request && !me_i_ack);
            // --- Commit on ack: existing pipeline commit behavior preserved ---
            if (!me_i_flush && me_i_ack) begin
                if (me_i_ce || !stall_bit) begin
                    me_o_opcode <= me_i_opcode;
                    me_o_rd_addr <= rd_addr_d;
                    me_o_rd_we <= rd_we_d;
                    me_o_rd_data <= rd_data_d;
                    me_o_load_data <= me_o_load_data_d;
                    me_o_funct3 <= funct_d;
                end
                rd_we_d <= 1'b0;
            // clear bus control outputs (these are also set below when starting transactions)
                me_o_we <= 1'b0;
                me_o_rd <= 1'b0;
                me_o_stb <= 1'b0;
                me_o_cyc <= 1'b0;
                me_o_ce <= 1'b0;
                byte_enable <= 4'b0000;
                pending_request <= 1'b0;
            end
            // --- Start a new request if available and we are idle ---
            if (me_i_ce && !pending_request && (me_i_opcode == `LOAD_WORD || me_i_opcode == `STORE_WORD)) begin
                pending_request <= 1'b1;
                funct_d <= me_i_funct3;
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
        me_o_rd = 1'b0;
        me_o_cyc = 1'b0;
        me_o_stb = 1'b0;
        if (me_i_ce && !pending_request) begin
            if (me_i_opcode == `STORE_WORD) begin
                me_o_we = 1'b1;
                me_o_cyc = 1'b1;
                me_o_stb = 1'b1;
            end
            else if (me_i_opcode == `LOAD_WORD) begin
                me_o_rd = 1'b1;
                me_o_cyc = 1'b1;
                me_o_stb = 1'b1;
            end
            else if (me_i_opcode == `RTYPE || me_i_opcode == `ITYPE || me_i_opcode == `JAL || 
                    me_i_opcode == `JALR || me_i_opcode == `LUI || me_i_opcode == `AUIPC) begin
                rd_we_d = 1'b1;
            end
        end
    end     

    always @(*) begin
        me_o_load_addr = {AWIDTH{1'b0}};
        me_o_store_addr = {AWIDTH{1'b0}};
        me_o_store_data = {DWIDTH{1'b0}};
        rd_addr_d = {AWIDTH{1'b0}};
        rd_data_d = {DWIDTH{1'b0}};
        case (me_i_opcode)
            `LOAD_WORD : begin
                me_o_opcode = me_i_opcode;
                me_o_load_addr = mem_addr;
                me_o_load_data_d = final_load;
            end
            `STORE_WORD : begin
                me_o_opcode = me_i_opcode;
                me_o_store_addr = mem_addr;
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
    // Store needs to align input data (from register → memory) and create byte_enable.
    always @(*) begin
        byte_enable = 4'd0;
        byte_enable_d = 4'd0;
        store_data_aligned = {DWIDTH{1'b0}};
        store_data_aligned_d = {DWIDTH{1'b0}};
        case (me_i_funct3)
            `FUNCT_SB : begin
                store_data_aligned = {4{me_i_rs2_data[7 : 0]}} << (byte_offset * 8);
                byte_enable = 4'b0001 << byte_offset;
            end
            `FUNCT_SH : begin
                case (byte_offset)
                    2'b00 : begin
                        store_data_aligned = {2{me_i_rs2_data[15 : 0]}} << (0 * 8);
                        byte_enable = 4'b0011;
                    end
                    2'b01 : begin
                        store_data_aligned = {2{me_i_rs2_data[15 : 0]}} << (1 * 8);
                        byte_enable = 4'b0110;
                    end
                    2'b10 : begin
                        store_data_aligned = {2{me_i_rs2_data[15 : 0]}} << (2 * 8);
                        byte_enable = 4'b1100;
                    end
                    2'b11 : begin
                        store_data_aligned = {4{me_i_rs2_data[15 : 8]}} << (2 * 8);
                        byte_enable = 4'b1000;
                        store_data_aligned_d = {4{me_i_rs2_data[7 : 0]}} << (0 * 8);
                        byte_enable_d = 4'b0001;
                    end
                endcase
            end
            `FUNCT_SW : begin
                store_data_aligned = me_i_rs2_data;
                byte_enable = 4'b1111;
            end
            default : begin
                store_data_aligned = {DWIDTH{1'b0}};
                byte_enable = 4'b0000;
            end 
        endcase
    end
    //Load needs to shift the output data (from memory → register) and extend correctly.
    reg [DWIDTH - 1 : 0] final_load;
    wire [DWIDTH - 1 : 0] raw = me_i_load_data >> (byte_offset * 8);
    always @(*) begin
        case (me_i_funct3)
            `FUNCT_LB : begin
                final_load = {{24{raw[7]}}, raw[7 : 0]};
            end
            `FUNCT_LBU : begin
                final_load = {24'b0, raw[7 : 0]};
            end
            `FUNCT_LH : begin
                final_load = {{16{raw[15]}}, raw[15 : 0]};
            end
            `FUNCT_LHU : begin
                final_load = {16'b0, raw[15 : 0]};
            end
            `FUNCT_LW : begin
                final_load = raw;
            end
            default : final_load = {DWIDTH{1'b0}}; 
        endcase
    end
endmodule
`endif 