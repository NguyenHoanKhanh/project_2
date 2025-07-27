`include "./source/decoder_stage.v"

module tb_decoder_stage;
    // Parameters
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter DEPTH = 1 << AWIDTH;
    parameter PC_WIDTH = 32;
    parameter IWIDTH = 32;

    // Signals
    reg ds_clk, ds_rst;
    reg [IWIDTH - 1 : 0] ds_i_instr;
    reg [PC_WIDTH - 1 : 0] ds_i_pc;
    reg ds_i_ce;
    reg ds_i_stall;
    reg ds_i_flush;
    reg [DWIDTH-1:0] ds_data_in_rd;
    reg ds_we;
    reg ds_read_reg;

    wire [PC_WIDTH - 1 : 0] ds_o_pc;
    wire [AWIDTH - 1 : 0] ds_o_addr_rs1_p;
    wire [AWIDTH - 1 : 0] ds_o_addr_rs2_p;
    wire [AWIDTH - 1 : 0] ds_o_addr_rd_p;
    wire [2 : 0] ds_o_funct3;
    wire [DWIDTH - 1 : 0] ds_o_imm;
    wire [`ALU_WIDTH - 1 : 0] ds_o_alu;
    wire [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    wire [`EXCEPTION_WIDTH - 1 : 0] ds_o_exception;
    wire ds_o_ce;
    wire ds_o_stall;
    wire ds_o_flush;
    wire [DWIDTH - 1 : 0] ds_data_out_rs1;
    wire [DWIDTH - 1 : 0] ds_data_out_rs2;

    // Instantiate decoder stage
    decoder_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .IWIDTH(IWIDTH)
    ) uut (
        .ds_clk(ds_clk),
        .ds_rst(ds_rst),
        .ds_i_instr(ds_i_instr),
        .ds_i_pc(ds_i_pc),
        .ds_o_pc(ds_o_pc),
        .ds_o_addr_rs1_p(ds_o_addr_rs1_p),
        .ds_o_addr_rs2_p(ds_o_addr_rs2_p),
        .ds_o_addr_rd_p(ds_o_addr_rd_p),
        .ds_o_funct3(ds_o_funct3),
        .ds_o_imm(ds_o_imm),
        .ds_o_alu(ds_o_alu),
        .ds_o_opcode(ds_o_opcode),
        .ds_o_exception(ds_o_exception),
        .ds_i_ce(ds_i_ce),
        .ds_o_ce(ds_o_ce),
        .ds_i_stall(ds_i_stall),
        .ds_o_stall(ds_o_stall),
        .ds_i_flush(ds_i_flush),
        .ds_o_flush(ds_o_flush),
        .ds_data_in_rd(ds_data_in_rd),
        .ds_data_out_rs1(ds_data_out_rs1),
        .ds_data_out_rs2(ds_data_out_rs2),
        .ds_we(ds_we),
        .ds_read_reg(ds_read_reg)
    );

    // Clock generation
    initial begin
        ds_clk = 0;
    end
    always #5 ds_clk = ~ds_clk;

    // Reset
    task reset;
        input integer n;
        integer i;
        begin
            ds_rst = 0;
            for (i=0; i<n; i=i+1) @(posedge ds_clk);
            ds_rst = 1;
            @(posedge ds_clk);
        end
    endtask

    // Stimulus
    initial begin
        // Init
        ds_i_instr = 0;
        ds_i_pc = 0;
        ds_i_ce = 0;
        ds_i_stall = 0;
        ds_i_flush = 0;
        ds_data_in_rd = 0;
        ds_we = 0;
        ds_read_reg = 0;

        reset(2);
        ds_i_ce = 1;

        // Test: simple ADD
        // instruction encoding for add x1,x2,x3
        ds_i_instr = 32'b0000000_00011_00010_000_00001_0110011;
        ds_i_pc    = 32'd4;
        ds_we      = 1; // write-back to RF
        ds_data_in_rd = 32'hDEADBEEF;
        ds_read_reg = 1;
        @(posedge ds_clk);
        @(posedge ds_clk);

        // Display outputs
        $display("pc=%0d rs1_p=%0d rs2_p=%0d rd_p=%0d data1=0x%h data2=0x%h funct3=%b imm=%0d opcode=%b alu=%b ex=%b",
                 ds_o_pc, ds_o_addr_rs1_p, ds_o_addr_rs2_p, ds_o_addr_rd_p,
                 ds_data_out_rs1, ds_data_out_rs2, ds_o_funct3,
                 ds_o_imm, ds_o_opcode, ds_o_alu, ds_o_exception);

        $finish;
    end
endmodule
