`include "./source/fetch_stage.v"
module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH = 32;
    parameter PC_WIDTH = 32;
    reg fi_clk, fi_rst;
    wire [IWIDTH - 1 : 0] fi_o_instr_fetch;
    wire [AWIDTH - 1 : 0] fi_o_addr_instr;
    reg fi_change_pc;
    reg [PC_WIDTH - 1 : 0] fi_alu_pc_value;
    wire [PC_WIDTH - 1 : 0] fi_pc;
    reg fi_i_stall;
    wire fi_o_stall, fi_o_ce;
    integer i;

    fetch_i #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH(AWIDTH),
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
        .fi_o_ce(fi_o_ce)
    );

    initial begin
        fi_clk = 1'b0;
        fi_i_stall = 1'b0;
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
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge fi_clk);
                $display($time, " ", "addr = %d, instruction = %h, syn = %b, ack = %b", i, fi_o_instr_fetch, fi.fi_i_syn, fi.fi_o_ack);
            end
        end
    endtask

    initial begin
        reset(2);
        @(posedge fi_clk);
        display(36);
        #200; $finish;
    end
endmodule