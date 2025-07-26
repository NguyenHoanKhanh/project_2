`include "./source/decoder.v"
module tb;
    parameter DWIDTH = 32;
    parameter IWIDTH = 32;
    parameter AWIDTH = 5;
    parameter DEPTH = 1 << AWIDTH;
    parameter PC_WIDTH = 32;

    reg d_clk, d_rst; 
    reg [IWIDTH - 1 : 0] d_i_instr;
    reg [PC_WIDTH - 1 : 0] d_i_pc;
    wire [PC_WIDTH - 1 : 0] d_o_pc;
    wire [AWIDTH - 1 : 0] d_o_addr_rs1, d_o_addr_rs1_p;
    wire [AWIDTH - 1 : 0] d_o_addr_rs2, d_o_addr_rs2_p;
    wire [AWIDTH - 1 : 0] d_o_addr_rd, d_o_addr_rd_p;
    wire [DWIDTH - 1 : 0] d_o_imm;
    wire [2 : 0] d_o_funct3;
    wire [`ALU_WIDTH - 1 : 0] d_o_alu;
    wire [`OPCODE_WIDTH - 1 : 0] d_o_opcode;
    wire [`EXCEPTION_WIDTH - 1 : 0] d_o_exception;
    reg d_i_ce;
    wire d_o_ce;
    reg d_i_stall;
    wire d_o_stall;
    reg d_i_flush;
    wire d_o_flush;

    decoder #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .DEPTH(DEPTH),
        .IWIDTH(IWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) d (
        .d_clk(d_clk), 
        .d_rst(d_rst), 
        .d_i_instr(d_i_instr), 
        .d_i_pc(d_i_pc), 
        .d_o_pc(d_o_pc), 
        .d_o_addr_rs1(d_o_addr_rs1), 
        .d_o_addr_rs1_p(d_o_addr_rs1_p), 
        .d_o_addr_rs2(d_o_addr_rs2), 
        .d_o_addr_rs2_p(d_o_addr_rs2_p), 
        .d_o_addr_rd(d_o_addr_rd), 
        .d_o_addr_rd_p(d_o_addr_rd_p), 
        .d_o_imm(d_o_imm), 
        .d_o_funct3(d_o_funct3), 
        .d_o_alu(d_o_alu), 
        .d_o_opcode(d_o_opcode), 
        .d_o_exception(d_o_exception), 
        .d_i_ce(d_i_ce), 
        .d_o_ce(d_o_ce), 
        .d_i_stall(d_i_stall), 
        .d_o_stall(d_o_stall), 
        .d_i_flush(d_i_flush), 
        .d_o_flush(d_o_flush)
    );

    initial begin
        d_clk = 1'b0;
        d_i_instr = {IWIDTH{1'b0}};
        d_i_pc = {PC_WIDTH{1'b0}};
        d_i_ce = 1'b0;
        d_i_stall = 1'b0;
        d_i_flush = 1'b0;
    end
    always #5 d_clk = ~d_clk;

    task reset (input integer  counter);
        begin
            d_rst = 1'b0;
            repeat(counter) @(posedge d_clk);
            d_rst = 1'b1;
        end
    endtask

    initial begin
        reset(2);
        @(posedge d_clk);
        d_i_ce = 1'b1;
        d_i_stall = 1'b0;
        d_i_flush = 1'b0;
        d_i_instr = 32'b00000000111101011111010100010011;
        d_i_pc = 32'd5;
        @(posedge d_clk);
        @(posedge d_clk);
        $display($time, " ", "d_o_addr_rs1 = %b, d_o_addr_rs2 = %b, d_o_addr_rd = %b, d_o_imm = %b, d_o_funct3 = %b, d_o_alu = %b, d_o_opcode = %b, d_o_exception = %b, d_o_pc = %b", d_o_addr_rs1, d_o_addr_rs2, d_o_addr_rd, d_o_imm, d_o_funct3, d_o_alu, d_o_opcode, d_o_exception, d_o_pc);
        #200; $finish;
    end
endmodule