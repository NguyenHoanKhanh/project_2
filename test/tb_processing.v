`include "./source/processing_unit.v"

module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;

    reg p_clk, p_rst;
    reg p_i_stall, p_i_flush;
    reg p_i_ce;
    wire [`OPCODE_WIDTH - 1 : 0] p_o_ws_opcode;
    wire [FUNCT_WIDTH - 1 : 0] p_o_ws_funct3;
    wire [DWIDTH - 1 : 0] p_o_ws_fw_ds_data_rd;
    wire [AWIDTH - 1 : 0] p_o_ws_addr_rd;
    wire [PC_WIDTH - 1 : 0] p_o_ws_next_pc;
    wire p_o_ws_stall, p_o_ws_flush;
    integer i;

    processing #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) p (
        .p_clk(p_clk),
        .p_rst(p_rst), 
        .p_i_stall(p_i_stall), 
        .p_i_flush(p_i_flush), 
        .p_i_ce(p_i_ce), 
        .p_o_ws_opcode(p_o_ws_opcode), 
        .p_o_ws_funct3(p_o_ws_funct3), 
        .p_o_ws_fw_ds_data_rd(p_o_ws_fw_ds_data_rd), 
        .p_o_ws_addr_rd(p_o_ws_addr_rd), 
        .p_o_ws_next_pc(p_o_ws_next_pc),
        .p_o_ws_stall(p_o_ws_stall),
        .p_o_ws_flush(p_o_ws_flush)
    );

    initial begin
        i = 0;
        p_clk = 1'b0;
    end
    always #5 p_clk = ~p_clk;

    initial begin
        $dumpfile("./waveform/processing.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            p_rst = 1'b0;
            repeat(counter) @(posedge p_clk);
            p_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            p_i_ce = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge p_clk);
                $display($time, " ", "p_o_ws_flush = %b , p_o_ws_stall = %b", p_o_ws_flush, p_o_ws_stall);
                $display($time, " ", "p_o_ws_opcode = %b, p_o_ws_funct3 = %b", p_o_ws_opcode, p_o_ws_funct3);
                $display($time, " ", "p_o_ws_addr_rd = %d , p_o_ws_fw_ds_data_rd = %d", p_o_ws_addr_rd, p_o_ws_fw_ds_data_rd);
                $display($time, " ", "p_o_ws_next_pc = %d", p_o_ws_next_pc);
            end
        end
    endtask

    initial begin
        reset(2);
        @(posedge p_clk);
        p_i_stall = 1'b0;
        p_i_flush = 1'b0;
        @(posedge p_clk);
        display(100);
        #20; $finish;
    end
endmodule