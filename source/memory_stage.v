`ifndef MEMORY_STAGE_V
`define MEMORY_STAGE_V

`include "./source/header.vh"
`include "./source/memory.v"
`include "./source/treat_load_store_data.v"
`include "./source/control_mem.v"
`include "./source/treat_data.v"

module mem_stage #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter FUNCT_WIDTH = 3
)(
    me_o_opcode, me_i_opcode, me_o_load_data,
    me_i_rs2_data, me_i_alu_value, me_o_flush, me_i_flush, me_o_stall, me_i_stall,
    me_o_ce, me_i_ce, me_rst, me_clk, me_i_rd_data, me_i_rd_addr, me_o_funct3,
    me_o_rd_addr, me_o_rd_data, me_o_rd_we, me_i_funct3, me_stall_from_alu
);
    input me_clk;
    input me_rst;
    input me_i_ce;
    input me_stall_from_alu;
    input me_i_stall;
    input me_i_flush;
    input [DWIDTH - 1 : 0] me_i_alu_value;
    input [DWIDTH - 1 : 0] me_i_rs2_data;
    input [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    input [AWIDTH - 1 : 0] me_i_rd_addr;
    input [DWIDTH - 1 : 0] me_i_rd_data;
    input [FUNCT_WIDTH - 1 : 0] me_i_funct3;

    output reg me_o_flush;
    output reg me_o_stall;
    output reg me_o_ce;
    output reg me_o_rd_we;
    output reg [`OPCODE_WIDTH - 1 : 0] me_o_opcode;
    output reg [DWIDTH - 1 : 0] me_o_load_data;
    output reg [AWIDTH - 1 : 0] me_o_rd_addr;
    output reg [DWIDTH - 1 : 0] me_o_rd_data;
    output reg [FUNCT_WIDTH - 1 : 0] me_o_funct3;

    wire me_o_cyc;
    wire me_o_stb;
    wire me_o_we;
    wire me_o_rd;
    wire [AWIDTH - 1 : 0] me_o_store_addr;
    wire [DWIDTH - 1 : 0] me_o_store_data;
    wire [AWIDTH - 1 : 0] me_o_load_addr;
    wire [DWIDTH - 1 : 0] me_i_load_data; 
    wire me_i_ack;

    wire [3 : 0] byte_enable;

    wire [AWIDTH - 1 : 0] mem_addr;
    assign mem_addr = me_i_alu_value >> 2;

    wire op_load = me_i_opcode[`LOAD_WORD];
    wire op_store = me_i_opcode[`STORE_WORD];
    wire op_rtype = me_i_opcode[`RTYPE];
    wire op_itype = me_i_opcode[`ITYPE];
    wire op_jal = me_i_opcode[`JAL];
    wire op_jalr = me_i_opcode[`JALR];
    wire op_lui = me_i_opcode[`LUI];
    wire op_auipc = me_i_opcode[`AUIPC];
    wire m_i_stall;

    control_mem cm (
        .clk(me_clk),
        .rst_n(me_rst),
        .me_i_ce(me_i_ce), 
        .me_i_opcode(me_i_opcode),
        .temp_pending_request(temp_pending_request), 
        .me_o_we(me_o_we), 
        .me_o_rd(me_o_rd), 
        .me_o_cyc(me_o_cyc), 
        .me_o_stb(me_o_stb), 
        .rd_we_d(rd_we_d)
    );

    wire [DWIDTH -1 : 0] final_load;
    // wire [3 : 0] byte_enable;
    load_store #(
        .DWIDTH(DWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) lt (
        .clk(me_clk),
        .rst_n(me_rst),
        .me_i_funct3(me_i_funct3), 
        .me_i_load_data(me_i_load_data), 
        .byte_off_q(byte_off_q), 
        .byte_offset_d(byte_offset_d), 
        .me_i_rs2_data(me_i_rs2_data),
        .final_load(final_load), 
        .store_data_aligned(store_data_aligned), 
        .byte_enable(byte_enable)
    );

    treat_data #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) td (
        .clk(me_clk),
        .rst_n(me_rst),
        .me_i_ce(me_i_ce), 
        .temp_pending_request(temp_pending_request), 
        .me_i_opcode(me_i_opcode),
        .store_data_aligned(store_data_aligned), 
        .mem_addr(mem_addr), 
        .me_i_rd_addr(me_i_rd_addr), 
        .me_i_alu_value(me_i_alu_value),
        .me_o_store_addr(me_o_store_addr), 
        .me_o_store_data(me_o_store_data), 
        .me_o_load_addr(me_o_load_addr),
        .rd_addr_d(rd_addr_d),
        .rd_data_d(rd_data_d)
    );

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
    //Pending will cause when me_i_stall is 1 => Data is being retrieved
    reg pending_request;
	reg temp_pending_request;
    // pipeline/commit registers (unchanged semantics)
    wire rd_we_d;
    wire [DWIDTH - 1 : 0] rd_data_d;
    wire [AWIDTH - 1 : 0] rd_addr_d;
    wire [DWIDTH - 1 : 0 ] store_data_aligned;
    
    reg [3 : 0] byte_enable_d;
    reg [DWIDTH - 1 : 0] store_data_aligned_d;

    reg [FUNCT_WIDTH - 1 : 0] funct_q;
    reg [1 : 0] byte_off_q;
	wire [1 : 0] byte_offset_d = me_i_alu_value[1 : 0];
    reg op_load_q;
    reg [`OPCODE_WIDTH - 1 : 0] opcode_q;
    reg [AWIDTH - 1 : 0] rd_addr_q;

    always @(posedge me_clk, negedge me_rst) begin
        if (!me_rst) begin
            // Initial output signal
            me_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            me_o_ce <= 1'b0;
            me_o_stall <= 1'b0;
            me_o_flush <= 1'b0;
            me_o_load_data <= {DWIDTH{1'b0}};
            me_o_rd_addr <= {AWIDTH{1'b0}};
            me_o_rd_data <= {DWIDTH{1'b0}};
            me_o_rd_we <= 1'b0;
            me_o_funct3 <= {FUNCT_WIDTH{1'b0}};

            //Initial internal signal
			temp_pending_request <= 1'b0;
            pending_request <= 1'b0;

            //Latch
            funct_q <= {FUNCT_WIDTH{1'b0}};
            byte_off_q <= 2'b0;
            op_load_q <= 1'b0;
            rd_addr_q <= {AWIDTH{1'b0}};
            opcode_q <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
			temp_pending_request <= pending_request;
            me_o_stall <= ((pending_request && !me_i_ack) || m_i_stall || me_i_stall || (me_stall_from_alu && me_i_ce)) && !me_i_flush;
            if (!pending_request && me_i_ce && !me_i_flush) begin
                if (!(op_load || op_store)) begin
                    me_o_opcode <= me_i_opcode;
                    me_o_funct3 <= me_i_funct3;
                    me_o_rd_addr <= me_i_rd_addr;
                    me_o_rd_data <= me_i_rd_data;
                    me_o_rd_we <= (op_rtype || op_itype || op_jal || op_jalr || op_lui || op_auipc) ? 1'b1 : 1'b0;
                end
                else if (me_i_ack || !stall_bit) begin
                    me_o_opcode <= opcode_q;
                    me_o_funct3 <= funct_q;
                    me_o_rd_addr <= rd_addr_d;
                    me_o_rd_data <= rd_data_d;
                    me_o_rd_we <= rd_we_d;
                    if (op_load_q) begin
                        me_o_rd_addr <= rd_addr_q;
                        me_o_rd_we <= 1'b1;
                        me_o_load_data <= final_load;
                    end
                    else begin
                        me_o_rd_we <= 1'b0;
                    end

                    pending_request <= 1'b1;    
                    funct_q <= me_i_funct3;
                    op_load_q <= op_load;
                    opcode_q <= me_i_opcode;
                    rd_addr_q <= me_i_rd_addr;
                    byte_off_q <= me_i_alu_value[1 : 0];
                end
            end
            // clear bus control outputs (these are also set below when starting transactions)
            else begin
                me_o_ce <= 1'b0;
                pending_request <= 1'b0;
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
endmodule
`endif 