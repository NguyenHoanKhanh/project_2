`include "./source/connect_fet_de.v"
module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter DWIDTH = 32;

    reg c_clk, c_rst;
    reg fi_i_stall, fi_i_flush, fi_i_ce;
    wire [IWIDTH - 1 : 0] fi_o_instr_fetch;
    wire [DWIDTH - 1 : 0] ds_data_out_rs2, ds_data_out_rs1;
    reg [DWIDTH - 1 : 0] ds_data_in_rd;
    wire [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    wire [`ALU_WIDTH - 1 : 0] ds_o_alu;
    wire [DWIDTH - 1 : 0] ds_o_imm;
    wire [FUNCT_WIDTH - 1 : 0] ds_o_funct3;
    wire [AWIDTH - 1 : 0] ds_o_addr_rd_p, ds_o_addr_rs1_p, ds_o_addr_rs2_p;
    reg ds_we;
    wire ds_o_stall, ds_o_flush, ds_o_ce;
    wire [PC_WIDTH - 1 : 0] ds_o_pc;
    integer i;

    connect # (
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .DWIDTH(DWIDTH)
    ) cn (
        .c_clk(c_clk), 
        .c_rst(c_rst), 
        .fi_i_stall(fi_i_stall), 
        .fi_i_flush(fi_i_flush), 
        .fi_i_ce(fi_i_ce), 
        .fi_o_instr_fetch(fi_o_instr_fetch), 
        .ds_data_out_rs2(ds_data_out_rs2), 
        .ds_data_out_rs1(ds_data_out_rs1),
        .ds_data_in_rd(ds_data_in_rd), 
        .ds_o_opcode(ds_o_opcode), 
        .ds_o_alu(ds_o_alu), 
        .ds_o_imm(ds_o_imm), 
        .ds_o_funct3(ds_o_funct3), 
        .ds_o_addr_rd_p(ds_o_addr_rd_p), 
        .ds_o_addr_rs1_p(ds_o_addr_rs1_p), 
        .ds_o_addr_rs2_p(ds_o_addr_rs2_p),
        .ds_we(ds_we),
        .ds_o_stall(ds_o_stall),
        .ds_o_flush(ds_o_flush),
        .ds_o_ce(ds_o_ce),
        .ds_o_pc(ds_o_pc)
    );

    initial begin
        c_clk = 1'b0;
        fi_i_stall = 1'b0;
        fi_i_flush = 1'b0;
        fi_i_ce = 1'b0;
        ds_data_in_rd = {DWIDTH{1'b0}};
        ds_we = 1'b0;
        i = 0;
    end
    always #5 c_clk = ~c_clk;

    initial begin
        $dumpfile("./waveform/connect.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            c_rst = 1'b0;
            repeat(counter) @(posedge c_clk);
            c_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            fi_i_ce = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge c_clk);
                $display($time, " ", "instr = %h, ", fi_o_instr_fetch);
                $display($time, " ", "ds_o_opcode = %b, ds_o_alu = %b, ds_o_funct3 = %b, ds_o_imm = %b, ", ds_o_opcode, ds_o_alu, ds_o_funct3, ds_o_imm);
                $display($time, " ", "ds_o_addr_rs1_p = %d, ds_data_out_rs1 = %d, ds_o_addr_rs2_p = %d, ds_data_out_rs2 = %d\n", ds_o_addr_rs1_p, ds_data_out_rs1, ds_o_addr_rs2_p, ds_data_out_rs2);
            end
            fi_i_ce = 1'b0;
            @(posedge c_clk);
        end
    endtask

    initial begin
        reset(2);
        @(posedge c_clk);
        for (i = 0; i < 5; i = i + 1) begin
            ds_we = 1'b1;
            ds_data_in_rd = i;
            @(posedge c_clk);
        end
        @(posedge c_clk);
        ds_we = 1'b0;
        display(37);
        #20;
        $finish;
    end
endmodule