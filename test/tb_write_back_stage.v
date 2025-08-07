`include "./source/write_back_stage.v"
module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter PC_WIDTH = 32;
    parameter FUNCT_WIDTH = 3;
    
    reg wb_clk, wb_rst;
    reg [`OPCODE_WIDTH - 1 : 0] wb_i_opcode;
    reg [DWIDTH - 1 : 0] wb_i_data_load;
    reg wb_i_we_rd;
    wire wb_o_we_rd;
    reg [AWIDTH - 1 : 0] wb_i_rd_addr;
    wire [AWIDTH - 1 : 0] wb_o_rd_addr;
    reg [DWIDTH - 1 : 0] wb_i_rd_data;
    wire [DWIDTH - 1 : 0] wb_o_rd_data;
    reg [PC_WIDTH - 1 : 0] wb_i_pc;
    wire [PC_WIDTH - 1 : 0] wb_o_next_pc;
    wire wb_o_change_pc;
    reg wb_i_ce;
    wire wb_o_stall, wb_o_flush;
    reg [DWIDTH - 1 : 0] wb_i_csr;
    reg [FUNCT_WIDTH - 1 : 0] wb_i_funct;
    reg wb_i_flush;
    reg wb_i_stall;

    writeback #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) wb (
        .wb_clk(wb_clk), 
        .wb_rst(wb_rst), 
        .wb_i_opcode(wb_i_opcode), 
        .wb_i_data_load(wb_i_data_load), 
        .wb_i_we_rd(wb_i_we_rd), 
        .wb_o_we_rd(wb_o_we_rd), 
        .wb_i_rd_addr(wb_i_rd_addr), 
        .wb_o_rd_addr(wb_o_rd_addr), 
        .wb_i_rd_data(wb_i_rd_data), 
        .wb_o_rd_data(wb_o_rd_data), 
        .wb_i_pc(wb_i_pc), 
        .wb_o_next_pc(wb_o_next_pc), 
        .wb_o_change_pc(wb_o_change_pc), 
        .wb_i_ce(wb_i_ce), 
        .wb_o_stall(wb_o_stall), 
        .wb_o_flush(wb_o_flush), 
        .wb_i_csr(wb_i_csr), 
        .wb_i_funct(wb_i_funct), 
        .wb_i_flush(wb_i_flush), 
        .wb_i_stall(wb_i_stall), 
        .wb_o_ce(wb_o_ce)
    );

    initial begin
        wb_clk = 1'b0;
        wb_i_opcode = {`OPCODE_WIDTH{1'b0}};
        wb_i_data_load = {DWIDTH{1'b0}};
        wb_i_we_rd = 1'b0;
        wb_i_rd_addr = {AWIDTH{1'b0}};
        wb_i_rd_data = {DWIDTH{1'b0}};
        wb_i_pc = {PC_WIDTH{1'b0}};
        wb_i_ce = 1'b0;
        wb_i_csr = {DWIDTH{1'b0}};
        wb_i_funct = {FUNCT_WIDTH{1'b0}};
        wb_i_flush = 1'b0;
        wb_i_stall = 1'b0;
    end
    always #5 wb_clk = ~wb_clk;

    task reset (input integer counter);
        begin
            wb_rst = 1'b0;
            repeat(counter) @(posedge wb_clk);
            wb_rst = 1'b1;
        end
    endtask

    initial begin
        reset(2);
        @(posedge wb_clk);
        wb_i_ce = 1'b1;
        @(posedge wb_clk);
        wb_i_we_rd = 1'b1;
        wb_i_rd_addr = 10;
        @(posedge wb_clk);
        wb_i_opcode = `LOAD;
        @(posedge wb_clk);
        wb_i_data_load = 32;
        @(posedge wb_clk);
        @(posedge wb_clk);
        $display($time, " ","wb_o_we = %b, wb_o_rd_addr = %d, wb_o_rd_data = %d, wb_o_next_pc = %d, wb_o_change_pc = %b, wb_o_stall = %b, wb_o_flush = %b", wb_o_we_rd, wb_o_rd_addr, wb_o_rd_data, wb_o_next_pc, wb_o_change_pc, wb_o_stall, wb_o_flush);
        @(posedge wb_clk);
        wb_i_ce = 0;
        @(posedge wb_clk);
        $display($time, " ","wb_o_we = %b, wb_o_rd_addr = %d, wb_o_rd_data = %d, wb_o_next_pc = %d, wb_o_change_pc = %b, wb_o_stall = %b, wb_o_flush = %b", wb_o_we_rd, wb_o_rd_addr, wb_o_rd_data, wb_o_next_pc, wb_o_change_pc, wb_o_stall, wb_o_flush);
        #200; $finish;
    end
endmodule