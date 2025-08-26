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
    reg [IWIDTH-1:0] ds_i_instr;
    reg [PC_WIDTH-1:0] ds_i_pc;
    reg ds_i_ce;
    reg ds_i_stall;
    reg ds_i_flush;
    reg [DWIDTH-1:0] ds_data_in_rd;
    reg ds_we;

    wire [PC_WIDTH-1:0] ds_o_pc;
    wire [AWIDTH-1:0] ds_o_addr_rs1_p;
    wire [AWIDTH-1:0] ds_o_addr_rs2_p;
    wire [AWIDTH-1:0] ds_o_addr_rd_p;
    wire [2:0] ds_o_funct3;
    wire [DWIDTH-1:0] ds_o_imm;
    wire [`ALU_WIDTH-1:0] ds_o_alu;
    wire [`OPCODE_WIDTH-1:0] ds_o_opcode;
    wire [`EXCEPTION_WIDTH-1:0] ds_o_exception;
    wire ds_o_ce;
    wire ds_o_stall;
    wire ds_o_flush;
    wire [DWIDTH-1:0] ds_data_out_rs1;
    wire [DWIDTH-1:0] ds_data_out_rs2;

    // instruction memory
    localparam NUM_INST = 52;
    reg [31:0] instr_mem [0:NUM_INST-1];
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

    // init instruction memory
    initial begin
        // fill same instructions you used earlier
        instr_mem[0]  = 32'h003100B3; // add x1,x2,x3
        instr_mem[1]  = 32'h40628233;
        instr_mem[2]  = 32'h009423B3;
        instr_mem[3]  = 32'h00C5B533;
        instr_mem[4]  = 32'h00F746B3;
        instr_mem[5]  = 32'h0128E833;
        instr_mem[6]  = 32'h015A79B3;
        instr_mem[7]  = 32'h018B9B33;
        instr_mem[8]  = 32'h01B5D9B3;
        instr_mem[9]  = 32'h41EEDEB3;
        instr_mem[10] = 32'h00510093;
        instr_mem[11] = 32'h00A22293;
        instr_mem[12] = 32'h00133313;
        instr_mem[13] = 32'h00F44393;
        instr_mem[14] = 32'hFFF55693;
        instr_mem[15] = 32'h00767613;
        instr_mem[16] = 32'h002E5D93;
        instr_mem[17] = 32'h0030F893;
        instr_mem[18] = 32'h4112A113;
        instr_mem[19] = 32'h01010003;
        instr_mem[20] = 32'h02022103;
        instr_mem[21] = 32'h0402A103;
        instr_mem[22] = 32'h0802B183;
        instr_mem[23] = 32'h00952823;
        instr_mem[24] = 32'h00B60C23;
        instr_mem[25] = 32'h01AD6A23;
        instr_mem[26] = 32'h00208663;
        instr_mem[27] = 32'h00210663;
        instr_mem[28] = 32'h00230663;
        instr_mem[29] = 32'h00238663;
        instr_mem[30] = 32'h00240663;
        instr_mem[31] = 32'h00248663;
        instr_mem[32] = 32'h400080EF;
        instr_mem[33] = 32'h01018167;
        instr_mem[34] = 32'h123452B7;
        instr_mem[35] = 32'h10000317;
        instr_mem[36] = 32'h003100B3;
        instr_mem[37] = 32'h00628233;
        instr_mem[38] = 32'h409403B3;
        instr_mem[39] = 32'h00C59533;
        instr_mem[40] = 32'h00F756B3;
        instr_mem[41] = 32'h4128D833;
        instr_mem[42] = 32'h00A08093;
        instr_mem[43] = 32'h0001A103;
        instr_mem[44] = 32'h000100E7;
        instr_mem[45] = 32'hFFF00293;
        instr_mem[46] = 32'h00532423;
        instr_mem[47] = 32'h00208863;
        instr_mem[48] = 32'h123451B7;
        instr_mem[49] = 32'h014000EF;
        instr_mem[50] = 32'h00000073;
        instr_mem[51] = 32'h00000013;
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
