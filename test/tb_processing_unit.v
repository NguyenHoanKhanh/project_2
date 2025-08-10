`include "./source/processing_unit.v"

module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;
    parameter AWIDTH = 5;
    parameter DWIDTH = 32;
    parameter FUNCT_WIDTH = 3;
    reg pe_clk;
    reg pe_rst;
    reg pe_fi_i_ce;
    reg pe_fi_i_stall;
    reg pe_fi_i_flush;
    wire [IWIDTH - 1 : 0] pe_fi_o_instr_fetch;
    wire [DWIDTH - 1 : 0] pe_wb_o_rd_data;
    wire [AWIDTH - 1 : 0] pe_wb_o_rd_addr;

    processing # (
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .DWIDTH(DWIDTH)
    ) p (
        .pe_clk(pe_clk),
        .pe_rst(pe_rst),
        .pe_fi_o_instr_fetch(pe_fi_o_instr_fetch),
        .pe_wb_o_rd_data(pe_wb_o_rd_data),
        .pe_wb_o_rd_addr(pe_wb_o_rd_addr),
        .pe_fi_i_flush(pe_fi_i_flush),
        .pe_fi_i_stall(pe_fi_i_stall),
        .pe_fi_i_ce(pe_fi_i_ce)
    );

    initial begin
        pe_clk = 1'b0;
    end
    always #5 pe_clk = ~pe_clk;

    initial begin
        $dumpfile("./waveform/processing_unit.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            pe_rst = 1'b0;
            repeat(counter) @(posedge pe_clk);
            pe_rst = 1'b1;
        end
    endtask

    task clock (input integer counter);
        begin
            repeat(counter) @(posedge pe_clk);
        end
    endtask

    initial begin
        reset(5);
        @(posedge pe_clk);
        pe_fi_i_ce = 1'b1;
        pe_fi_i_stall = 1'b0;
        pe_fi_i_flush = 1'b0;
        clock(10000);
        $monitor($time, " ", "pe_fi_o_instr_fetch = %h, pe_wb_o_rd_data = %d, pe_wb_o_rd_addr = %d", pe_fi_o_instr_fetch, pe_wb_o_rd_data, pe_wb_o_rd_addr);
        #200; $finish;
    end
endmodule