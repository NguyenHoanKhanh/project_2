`timescale 1ns/1ps
`include "./source/header.vh"
`include "./source/decoder.v"

module tb_decoder;
    // Parameters
    parameter DWIDTH     = 32;
    parameter IWIDTH     = 32;
    parameter AWIDTH     = 5;
    parameter PC_WIDTH   = 32;
    parameter CLK_PERIOD = 10;

    // Signals
    reg  d_clk;
    reg  d_rst;
    reg  [IWIDTH-1:0]     d_i_instr;
    reg  [PC_WIDTH-1:0]   d_i_pc;
    reg  d_i_ce;
    reg  d_i_stall;
    reg  d_i_flush;

    wire [PC_WIDTH-1:0]       d_o_pc;
    wire [AWIDTH-1:0]         d_o_addr_rs1;
    wire [AWIDTH-1:0]         d_o_addr_rs2;
    wire [AWIDTH-1:0]         d_o_addr_rd;
    wire [AWIDTH-1:0]         d_o_addr_rs1_p;
    wire [AWIDTH-1:0]         d_o_addr_rs2_p;
    wire [AWIDTH-1:0]         d_o_addr_rd_p;
    wire [DWIDTH-1:0]         d_o_imm;
    wire [2:0]                d_o_funct3;
    wire [`ALU_WIDTH-1:0]     d_o_alu;
    wire [`OPCODE_WIDTH-1:0]  d_o_opcode;
    wire [`EXCEPTION_WIDTH-1:0] d_o_exception;
    wire                      d_o_ce;
    wire                      d_o_stall;
    wire                      d_o_flush;

    // Instantiate decoder
    decoder #(
        .DWIDTH(DWIDTH),
        .IWIDTH(IWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) uut (
        .d_clk(d_clk),
        .d_rst(d_rst),
        .d_i_instr(d_i_instr),
        .d_i_pc(d_i_pc),
        .d_i_ce(d_i_ce),
        .d_i_stall(d_i_stall),
        .d_i_flush(d_i_flush),
        .d_o_pc(d_o_pc),
        .d_o_addr_rs1(d_o_addr_rs1),
        .d_o_addr_rs2(d_o_addr_rs2),
        .d_o_addr_rd(d_o_addr_rd),
        .d_o_addr_rs1_p(d_o_addr_rs1_p),
        .d_o_addr_rs2_p(d_o_addr_rs2_p),
        .d_o_addr_rd_p(d_o_addr_rd_p),
        .d_o_imm(d_o_imm),
        .d_o_funct3(d_o_funct3),
        .d_o_alu(d_o_alu),
        .d_o_opcode(d_o_opcode),
        .d_o_exception(d_o_exception),
        .d_o_ce(d_o_ce),
        .d_o_stall(d_o_stall),
        .d_o_flush(d_o_flush)
    );

    // Clock generation
    initial begin
        d_clk = 1'b0;
    end
    always #5 d_clk = ~d_clk;
    // Reset task
    task reset;
        integer i;
        begin
            d_rst = 1'b0;
            for (i = 0; i < 2; i = i + 1) @(posedge d_clk);
            d_rst = 1'b1;
            @(posedge d_clk);
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize
        d_i_instr  = 0;
        d_i_pc     = 0;
        d_i_ce     = 1'b0;
        d_i_stall  = 1'b0;
        d_i_flush  = 1'b0;
        reset;
        d_i_ce = 1'b1;

        // 1) R-type: add x1, x2, x3
        d_i_instr = {7'b0000000, 5'd3, 5'd2, `FUNCT3_ADD, 5'd1, `OPCODE_RTYPE};
        d_i_pc    = 32'd4; #(CLK_PERIOD*2);
        $display("R ADD:   rs1=%0d rs2=%0d rd=%0d alu[%b] opcode=%b", d_o_addr_rs1, d_o_addr_rs2, d_o_addr_rd, d_o_alu, d_o_opcode);

        // 2) R-type: sub x4, x5, x6
        d_i_instr = {7'b0100000, 5'd6, 5'd5, `FUNCT3_ADD, 5'd4, `OPCODE_RTYPE};
        d_i_pc    = 32'd8; #(CLK_PERIOD*2);
        $display("R SUB:   rs1=%0d rs2=%0d rd=%0d alu[%b] opcode=%b", d_o_addr_rs1, d_o_addr_rs2, d_o_addr_rd, d_o_alu, d_o_opcode);

        // 3) I-type: addi x7, x8, 16
        d_i_instr = {12'd16, 5'd8, `FUNCT3_ADD, 5'd7, `OPCODE_ITYPE};
        d_i_pc    = 32'd12; #(CLK_PERIOD*2);
        $display("I ADDI:  rs1=%0d imm=%0d rd=%0d opcode=%b", d_o_addr_rs1, $signed(d_o_imm), d_o_addr_rd, d_o_opcode);

        // 4) Load: lw x9, 4(x10)
        d_i_instr = {12'd4, 5'd10, 3'b010, 5'd9, `OPCODE_LOAD};
        d_i_pc    = 32'd16; #(CLK_PERIOD*2);
        $display("LOAD:    rs1=%0d imm=%0d rd=%0d opcode=%b", d_o_addr_rs1, $signed(d_o_imm), d_o_addr_rd, d_o_opcode);

        // 5) Store: sw x11, 8(x12)
        d_i_instr = {7'b0000000, 5'd11, 5'd12, 3'b010, 5'd8, `OPCODE_STORE};
        d_i_pc    = 32'd20; #(CLK_PERIOD*2);
        $display("STORE:   rs1=%0d rs2=%0d imm=%0d opcode=%b", d_o_addr_rs1, d_o_addr_rs2, $signed(d_o_imm), d_o_opcode);

        // 6) Branch: beq x13, x14, 2
        d_i_instr = {1'b0, 6'b000000, 5'd14, 5'd13, 3'b000, 4'b0010, 1'b0, `OPCODE_BRANCH};
        d_i_pc    = 32'd24; #(CLK_PERIOD*2);
        $display("BRANCH:  rs1=%0d rs2=%0d imm=%0d opcode=%b", d_o_addr_rs1, d_o_addr_rs2, $signed(d_o_imm), d_o_opcode);

        // 7) JAL: jal x15, 16
        d_i_instr = {1'b0, 8'd16, 1'b0, 10'd16, 1'b0, 5'd15, `OPCODE_JAL};
        d_i_pc    = 32'd28; #(CLK_PERIOD*2);
        $display("JAL:     rd=%0d imm=%0d opcode=%b", d_o_addr_rd, $signed(d_o_imm), d_o_opcode);

        // 8) JALR: jalr x16, x17, 20
        d_i_instr = {12'd20, 5'd17, `FUNCT3_ADD, 5'd16, `OPCODE_JALR};
        d_i_pc    = 32'd32; #(CLK_PERIOD*2);
        $display("JALR:    rs1=%0d imm=%0d rd=%0d opcode=%b", d_o_addr_rs1, $signed(d_o_imm), d_o_addr_rd, d_o_opcode);

        // 9) LUI: lui x18, 0x12345
        d_i_instr = {20'h12345, 5'd18, `OPCODE_LUI};
        d_i_pc    = 32'd36; #(CLK_PERIOD*2);
        $display("LUI:     rd=%0d imm=%h opcode=%b", d_o_addr_rd, d_o_imm, d_o_opcode);

        // 10) AUIPC: auipc x19, 0xABCDE
        d_i_instr = {20'hABCDE, 5'd19, `OPCODE_AUIPC};
        d_i_pc    = 32'd40; #(CLK_PERIOD*2);
        $display("AUIPC:   rd=%0d imm=%h opcode=%b", d_o_addr_rd, d_o_imm, d_o_opcode);

        $finish;
    end
endmodule
