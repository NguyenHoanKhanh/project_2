`timescale 1ns/1ps
`include "./source/decoder_stage.v"

module tb_decoder_stage_alt;
    // Parameters
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter PC_WIDTH = 32;
    parameter IWIDTH = 32;

    reg ds_clk;
    reg ds_rst; 
    reg [IWIDTH - 1 : 0] ds_i_instr;
    reg [PC_WIDTH - 1 : 0] ds_i_pc;
    reg ds_i_ce;
    reg ds_i_stall;
    reg ds_i_flush;
    reg [DWIDTH - 1 : 0] ds_data_in_rd;
    reg ds_we;

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

    // instruction memory
    localparam NUM_INST = 36;
    integer counter;
    reg [31 : 0] instr_mem [0 : NUM_INST - 1];
    integer i;

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
        .ds_we(ds_we)
    );

    // Clock
    initial begin
        ds_clk = 0;
    end
    always #5 ds_clk = ~ds_clk; 

    // waveform
    initial begin
        $dumpfile("./waveform/decoder_stage.vcd");
        $dumpvars(0, tb_decoder_stage_alt);
    end

    // Reset task (active low)
    task reset(input integer cycles);
    begin
        ds_rst = 1'b0; 
        repeat(cycles) @(posedge ds_clk);
        ds_rst = 1'b1; 
        @(posedge ds_clk);
    end
    endtask
    
    initial begin
        $readmemh("./source/instr.txt", instr_mem, 0, NUM_INST - 1);
        counter = 0;
    end

    // drive the decoder with all instructions 
    initial begin 
        // init signals and reset 
        ds_i_instr = 0; 
        ds_i_pc = 0; 
        ds_i_ce = 0; 
        ds_i_stall = 0; 
        ds_i_flush = 0; 
        ds_data_in_rd = 0; 
        ds_we = 0; 
        reset(2); 
        @(posedge ds_clk); 
        for (i = 0; i < NUM_INST; i = i + 1) begin 
            ds_i_instr = instr_mem[i]; 
            ds_i_pc = i * 4; 
            ds_data_in_rd = 32'hDEADBEEF ^ i; 
            ds_we = 1; 
            ds_i_ce = 1; 
            @(posedge ds_clk); 
            ds_i_ce = 0; 
            $display("STEP %0d: pc=%0d instr=%08x -> rd_p=%0d rs1_p=%0d rs2_p=%0d opcode=%b funct3=%b ex=%b alu=%b imm=0x%h", i, ds_o_pc, 
            ds_i_instr, ds_o_addr_rd_p, ds_o_addr_rs1_p, ds_o_addr_rs2_p, ds_o_opcode, ds_o_funct3, ds_o_exception, ds_o_alu, ds_o_imm); 
            @(posedge ds_clk); 
            end
            #200; $finish; 
        end 
endmodule
