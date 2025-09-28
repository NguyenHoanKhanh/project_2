`timescale 1ns/1ps
`include "./source/write_back_stage.v"

module tb_writeback;
    parameter DWIDTH      = 32;
    parameter AWIDTH      = 5;
    parameter PC_WIDTH    = 32;
    parameter FUNCT_WIDTH = 3;

    // Inputs to DUT
    reg                         wb_clk;
    reg                         wb_rst;
    reg [FUNCT_WIDTH-1:0]       wb_i_funct;
    reg [`OPCODE_WIDTH-1:0]     wb_i_opcode;
    reg [DWIDTH-1:0]            wb_i_data_load;
    reg                         wb_i_we_rd;
    reg [AWIDTH-1:0]            wb_i_rd_addr;
    reg [DWIDTH-1:0]            wb_i_rd_data;
    reg [PC_WIDTH-1:0]          wb_i_pc;
    reg                         wb_i_ce;
    reg                         wb_i_stall;
    reg                         wb_i_flush;

    // Outputs from DUT
    wire                        wb_o_we_rd;
    wire [AWIDTH-1:0]           wb_o_rd_addr;
    wire [DWIDTH-1:0]           wb_o_rd_data;
    wire [PC_WIDTH-1:0]         wb_o_next_pc;
    reg                         wb_i_change_pc;
    wire                        wb_o_change_pc;
    wire                        wb_o_ce;
    wire                        wb_o_stall;
    wire                        wb_o_flush;
    wire [`OPCODE_WIDTH - 1 : 0] wb_o_opcode;
    wire [FUNCT_WIDTH - 1 : 0] wb_o_funct;

    // Instantiate writeback module
    write_back_stage #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) uut (
        .wb_clk        (wb_clk),
        .wb_rst        (wb_rst),
        .wb_i_funct    (wb_i_funct),
        .wb_i_opcode   (wb_i_opcode),
        .wb_i_data_load(wb_i_data_load),
        .wb_i_we_rd    (wb_i_we_rd),
        .wb_o_we_rd    (wb_o_we_rd),
        .wb_i_rd_addr  (wb_i_rd_addr),
        .wb_i_rd_data  (wb_i_rd_data),
        .wb_o_rd_addr  (wb_o_rd_addr),
        .wb_o_rd_data  (wb_o_rd_data),
        .wb_i_pc       (wb_i_pc),
        .wb_o_next_pc  (wb_o_next_pc),
        .wb_i_change_pc(wb_i_change_pc),
        .wb_o_change_pc(wb_o_change_pc),
        .wb_i_ce       (wb_i_ce),
        .wb_o_ce       (wb_o_ce),
        .wb_i_stall    (wb_i_stall),
        .wb_o_stall    (wb_o_stall),
        .wb_i_flush    (wb_i_flush),
        .wb_o_flush    (wb_o_flush),
        .wb_o_opcode   (wb_o_opcode),
        .wb_o_funct    (wb_o_funct)
    );

    // Clock generation
    initial begin
        wb_clk = 0;
    end
    always #5 wb_clk = ~wb_clk;

    initial begin
        $dumpfile("./waveform/writeback.vcd");
        $dumpvars(0, tb_writeback);
    end
    
    // Reset task
    task reset(input integer cycles);
        begin
            wb_rst = 0;
            repeat(cycles) @(posedge wb_clk);
            wb_rst = 1;
        end
    endtask

    function [`OPCODE_WIDTH - 1 : 0] opc;
        input integer idx;
        begin
            opc = {`OPCODE_WIDTH{1'b0}};
            opc[idx] = 1'b1;
        end
    endfunction

    initial begin
        // Initialize inputs
        wb_i_funct    = 0;
        wb_i_opcode   = 0;
        wb_i_data_load= 0;
        wb_i_we_rd    = 0;
        wb_i_rd_addr  = 0;
        wb_i_rd_data  = 0;
        wb_i_pc       = 0;
        wb_i_ce       = 0;
        wb_i_stall    = 0;
        wb_i_flush    = 0;
        wb_i_change_pc = 0;

        // Apply reset
        reset(2);
        @(posedge wb_clk);

        // Scenario: load instruction
        wb_i_ce        = 1;
        wb_i_we_rd     = 1;
        wb_i_opcode    = opc(`LOAD_WORD);
        wb_i_change_pc = 1;
        wb_i_funct     = 3'd0;
        wb_i_rd_addr   = 5'd10;
        @(posedge wb_clk);

        wb_i_data_load = 32'hDEADBEEF;
        @(posedge wb_clk);

        // check outputs
        $display("%0t: we_rd=%b, rd_addr=%d, rd_data=0x%h, next_pc=%d, change_pc=%b, stall=%b, flush=%b, ce=%b", 
                 $time, wb_o_we_rd, wb_o_rd_addr, wb_o_rd_data, wb_o_next_pc, wb_o_change_pc, wb_o_stall, wb_o_flush, wb_o_ce);
        $display($time, " ", "wb_o_opcode = %b, wb_o_funct = %b", wb_o_opcode, wb_o_funct);

        // End CE
        wb_i_ce = 0;
        @(posedge wb_clk);
        $display("%0t: (after CE=0) stall=%b, flush=%b, change_pc=%b", $time, wb_o_stall, wb_o_flush, wb_o_change_pc);

        #50 $finish;
    end
endmodule
