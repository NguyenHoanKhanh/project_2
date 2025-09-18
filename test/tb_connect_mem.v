`include "./source/connect_fet_de_ex_mem.v"

module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;

    reg fm_clk, fm_rst;
    reg fm_i_ce;
    reg fm_i_stall, fm_i_flush;
    wire [`OPCODE_WIDTH - 1 : 0] fm_o_opcode_n;
    wire fm_o_flush_n, fm_o_stall_n;
    wire fm_o_ce_n;
    wire [FUNCT_WIDTH - 1 : 0] fm_o_funct3_n;
    wire [AWIDTH - 1 : 0] fm_o_rd_addr;
    wire [DWIDTH - 1 : 0] fm_o_rd_data; 
    wire fm_o_rd_we;
    wire [DWIDTH - 1 : 0] fm_o_load_data;
    wire fm_change_pc;
    wire [PC_WIDTH - 1 : 0] fm_pc_n;
    integer i;

    connect_mem #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) cm (
        .fm_clk(fm_clk), 
        .fm_rst(fm_rst), 
        .fm_i_ce(fm_i_ce), 
        .fm_i_stall(fm_i_stall), 
        .fm_i_flush(fm_i_flush), 
        .fm_o_flush_n(fm_o_flush_n), 
        .fm_o_opcode_n(fm_o_opcode_n),
        .fm_o_stall_n(fm_o_stall_n), 
        .fm_o_ce_n(fm_o_ce_n), 
        .fm_o_funct3_n(fm_o_funct3_n), 
        .fm_o_rd_addr(fm_o_rd_addr), 
        .fm_o_rd_data(fm_o_rd_data), 
        .fm_o_rd_we(fm_o_rd_we), 
        .fm_o_load_data(fm_o_load_data),
        .fm_pc_n(fm_pc_n),
        .fm_change_pc(fm_change_pc)
    );
    
    initial begin
        i = 0;
        fm_i_ce = 1'b0;
        fm_clk = 1'b0;
    end
    always #5 fm_clk = ~fm_clk;

    initial begin
        $dumpfile("./waveform/connect_mem.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            fm_rst = 1'b0;
            repeat(counter) @(posedge fm_clk);
            fm_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            fm_i_ce = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge fm_clk);
                $display($time, " ", "fm_o_flush_n = %b, fm_o_stall_n = %b, fm_o_ce_n = %b", fm_o_flush_n, fm_o_stall_n, fm_o_ce_n);
                @(posedge fm_clk);
                $display($time, " ", "fm_change_pc = %b", fm_change_pc);
                $display($time, " ", "fm_pc_n = %d", fm_pc_n);
                $display($time, " ", "fm_o_opcode_n = %b, fm_o_funct3 = %b", fm_o_opcode_n, fm_o_funct3_n);
                $display($time, " ", "fm_o_load_data = %d", fm_o_load_data);
                $display($time, " ", "fm_o_rd_we = %b, fm_o_rd_addr = %d, fm_o_rd_data = %d\n", fm_o_rd_we, fm_o_rd_addr, fm_o_rd_data);
                @(posedge fm_clk);
            end
            @(posedge fm_clk);
            fm_i_ce = 1'b0;
        end
    endtask

    initial begin
        reset(2);
        @(posedge fm_clk);
        fm_i_stall = 1'b0;
        fm_i_flush = 1'b0;
        display(100);
        #20; $finish;
    end
endmodule