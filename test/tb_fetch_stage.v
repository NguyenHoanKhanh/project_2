`include "./source/fetch_stage.v"
module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;
    reg fi_clk, fi_rst;
    wire [IWIDTH - 1 : 0] fi_o_instr_fetch;
    wire [AWIDTH_INSTR - 1 : 0] fi_o_addr_instr;
    reg fi_change_pc;
    reg [PC_WIDTH - 1 : 0] fi_alu_pc_value;
    wire [PC_WIDTH - 1 : 0] fi_pc;
    reg fi_i_stall;
    reg fi_i_ce;
    wire fi_o_stall, fi_o_ce;
    reg fi_i_flush;
    wire fi_o_flush;
    integer i;

    fetch_i #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) fi (
        .fi_clk(fi_clk), 
        .fi_rst(fi_rst), 
        .fi_o_instr_fetch(fi_o_instr_fetch), 
        .fi_o_addr_instr(fi_o_addr_instr), 
        .fi_change_pc(fi_change_pc), 
        .fi_alu_pc_value(fi_alu_pc_value), 
        .fi_pc(fi_pc), 
        .fi_i_stall(fi_i_stall), 
        .fi_o_stall(fi_o_stall), 
        .fi_i_ce(fi_i_ce),
        .fi_o_ce(fi_o_ce),
        .fi_i_flush(fi_i_flush),
        .fi_o_flush(fi_o_flush)
    );

    initial begin
        fi_clk = 1'b0;
        fi_i_stall = 1'b0;
        fi_i_flush = 1'b0;
        fi_i_ce = 1'b0;
        i = 0;
    end
    always #5 fi_clk = ~fi_clk;

    initial begin
        $dumpfile("./waveform/fetch_stage.vcd");
        $dumpvars(0, tb);
    end

    task reset(input integer counter);
        begin 
            fi_rst = 1'b0;
            repeat(counter) @(posedge fi_clk);
            fi_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            fi_i_ce = 1'b1; 
            @(posedge fi_clk)
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge fi_clk)
                $display($time, " ", "addr = %d, instruction = %h, syn = %b, ack = %b, fi_o_last = %b", i, fi_o_instr_fetch, fi.fi_i_syn, fi.fi_o_ack, fi.fi_o_last);
            end
        end
    endtask

    initial begin
        fi_i_stall = 1'b0;
        fi_i_flush = 1'b0;
        reset(2);
        // @(posedge fi_clk)
        display(36);
        $finish;
    end
endmodule