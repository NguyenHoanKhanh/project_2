`include "./source/datapath.v"

module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;

    reg d_clk, d_rst;
    reg d_i_ce;
    reg d_i_stall, d_i_flush;
    wire d_o_flush_n, d_o_stall_n;
    wire [AWIDTH - 1 : 0] d_o_addr_rd_n;
    wire [DWIDTH - 1 : 0] d_o_data_rd_n;
    wire d_o_change_pc_n;
    wire [PC_WIDTH - 1 : 0] d_o_pc_n;
    wire [`OPCODE_WIDTH - 1 : 0] d_o_opcode_n;
    wire [FUNCT_WIDTH - 1 : 0] d_o_funct3_n;
    integer i;

    datapath #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) d (
        .d_clk(d_clk), 
        .d_rst(d_rst), 
        .d_i_ce(d_i_ce), 
        .d_i_stall(d_i_stall), 
        .d_o_stall_n(d_o_stall_n), 
        .d_i_flush(d_i_flush), 
        .d_o_flush_n(d_o_flush_n), 
        .d_o_addr_rd_n(d_o_addr_rd_n), 
        .d_o_data_rd_n(d_o_data_rd_n), 
        .d_o_pc_n(d_o_pc_n), 
        .d_o_opcode_n(d_o_opcode_n), 
        .d_o_funct3_n(d_o_funct3_n), 
        .d_o_change_pc_n(d_o_change_pc_n)
    );

    initial begin
        d_clk = 1'b0;
        i = 0;
    end
    always #5 d_clk = ~d_clk;

    initial begin
        $dumpfile("./waveform/datapath.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            d_rst = 1'b0;
            repeat(counter) @(posedge d_clk);
            d_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            d_i_ce = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge d_clk);
                $display($time, " ", "d_o_stall_n = %b, d_o_flush_n = %b", d_o_stall_n, d_o_flush_n);
                $display($time, " ", "d_o_addr_rd_n = %d, d_o_data_rd_n = %d", d_o_addr_rd_n, d_o_data_rd_n);
                $display($time, " ", "d_o_change_pc_n = %b, d_o_pc_n = %d", d_o_change_pc_n, d_o_pc_n);
                $display($time, " ", "d_o_funct3_n = %b, d_o_opcode_n = %b", d_o_funct3_n, d_o_opcode_n);
            end
            @(posedge d_clk);
            d_i_ce = 1'b0;
        end
    endtask

    initial begin
        d_i_stall = 1'b0;
        d_i_flush = 1'b0;
        reset(2);
        display(100);
        #20; $finish;
    end
endmodule