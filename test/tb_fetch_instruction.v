`timescale 1ns/1ps
`include "./source/fetch_instruction.v"

module tb_instruction_fetch;
    // Parameters
    parameter IWIDTH        = 32;
    parameter AWIDTH_INSTR  = 32;
    parameter PC_WIDTH      = 32;
    parameter DEPTH         = 64; // local memory entries for TB

    // Clock and reset
    reg                    f_clk;
    reg                    f_rst;

    // DUT interface
    reg  [IWIDTH-1:0]      f_i_instr;        // data from "transmit" (emulated here)
    wire [IWIDTH-1:0]      f_o_instr;        // output of fetch (to decoder)
    wire [AWIDTH_INSTR-1:0] f_o_addr_instr;
    wire                   f_o_syn;          // request from fetch (to mem/transmit)
    reg                    f_i_ack;          // ack from mem/transmit (emulated)
    reg                    f_i_stall;        // downstream stall input (consumer busy)
    wire                   f_o_stall;        // fetch asserts when it cannot accept more requests
    reg                    f_i_ce;           // allow fetch
    wire                   f_o_ce;           // valid output to downstream
    reg                    f_i_flush;
    wire                   f_o_flush;
    reg                    f_change_pc;
    reg  [PC_WIDTH-1:0]    f_alu_pc_value;
    wire [PC_WIDTH-1:0]    f_pc;

    // Instantiate DUT
    instruction_fetch #(
        .IWIDTH(IWIDTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) dut (
        .f_clk         (f_clk),
        .f_rst         (f_rst),
        .f_i_instr     (f_i_instr),
        .f_o_instr     (f_o_instr),
        .f_o_addr_instr(f_o_addr_instr),
        .f_change_pc   (f_change_pc),
        .f_alu_pc_value(f_alu_pc_value),
        .f_pc          (f_pc),
        .f_o_syn       (f_o_syn),
        .f_i_ack       (f_i_ack),
        .f_i_stall     (f_i_stall),
        .f_o_stall     (f_o_stall),
        .f_i_ce        (f_i_ce),
        .f_o_ce        (f_o_ce),
        .f_i_flush     (f_i_flush),
        .f_o_flush     (f_o_flush)
    );

    // Simple memory to emulate transmit: feed deterministic words
    reg [IWIDTH-1:0] mem [0:DEPTH-1];
    integer mem_ptr;

    // Clock
    initial begin
        f_clk = 0;
        forever #5 f_clk = ~f_clk; // 10 ns period
    end

    // Waveform
    initial begin
        $dumpfile("./waveform/fetch_instruction.vcd");
        $dumpvars(0, tb_instruction_fetch);
    end

    // Reset task
    task do_reset(input integer cycles);
        begin
            f_rst = 0;
            repeat(cycles) @(posedge f_clk);
            f_rst = 1;
            @(posedge f_clk);
        end
    endtask

    // Stall task (downstream busy)
    task introduce_stall(input integer cycles);
        begin
            f_i_stall = 1;
            repeat(cycles) @(posedge f_clk);
            f_i_stall = 0;
            @(posedge f_clk);
        end
    endtask

    // Jump task: request PC change for one cycle
    task do_jump(input [PC_WIDTH-1:0] pc);
        begin
            f_alu_pc_value = pc;
            f_change_pc    = 1;
            @(posedge f_clk);
            f_change_pc = 0;
            @(posedge f_clk);
        end
    endtask

    // Flush task: assert flush for given cycles
    task do_flush(input integer cycles);
        integer i;
        begin
            f_i_flush = 1;
            @(posedge f_clk);
            for (i = 1; i < cycles; i = i + 1)
                @(posedge f_clk);
            f_i_flush = 0;
            @(posedge f_clk);
        end
    endtask

    // Emulate transmit/memory behavior:
    // - When f_o_syn==1, present f_i_instr = mem[mem_ptr] and assert f_i_ack = 1 for that cycle.
    // - Advance mem_ptr each time f_o_syn is asserted.
    always @(posedge f_clk or negedge f_rst) begin
        if (!f_rst) begin
            f_i_instr <= {IWIDTH{1'b0}};
            f_i_ack   <= 1'b0;
            mem_ptr   <= 0;
        end else begin
            if (f_o_syn) begin
                f_i_instr <= mem[mem_ptr];
                f_i_ack   <= 1'b1;
                // advance pointer so next request gets next instruction
                if (mem_ptr < DEPTH-1) mem_ptr <= mem_ptr + 1;
                else mem_ptr <= 0;
            end else begin
                f_i_ack <= 1'b0;
            end
        end
    end

    // Initialize memory with recognizable patterns
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h1000_0000 + i; // simple increasing patterns for visibility
        end
    end

    // Monitoring: print concise table each cycle
    initial begin
        $display("TIME clk rst | pc    addr_req  instr_in   syn ack stall_i stall_o ce out_flush");
        $display("--------------------------------------------------------------------------");
        forever @(posedge f_clk) begin
            $display("%4t  %b   %h | %h | %h | %h | %b | %b   |   %b   |   %b  |  %b",
                     $time, f_clk, f_rst,
                     f_pc, f_o_addr_instr, f_i_instr,
                     f_o_syn, f_i_ack, f_i_stall, f_o_stall, f_o_ce, f_o_flush);
        end
    end

    // Test sequence
    initial begin
        // defaults
        f_i_instr       = 0;
        f_i_ack         = 0;
        f_i_stall       = 0;
        f_change_pc     = 0;
        f_alu_pc_value  = 0;
        f_i_flush       = 0;
        f_i_ce          = 1; // allow fetch to start
        // reset
        do_reset(2);

        // let DUT run and fetch a few instructions automatically
        repeat (6) @(posedge f_clk); // observe startup

        // introduce stall for 4 cycles (downstream busy)
        $display(">>> Introduce stall (4 cycles)");
        introduce_stall(4);

        // wait a few cycles
        repeat (4) @(posedge f_clk);

        // jump to 0x100
        $display(">>> Jump to 0x100");
        do_jump(32'h00000100);

        // let fetch run a few cycles
        repeat (6) @(posedge f_clk);

        // flush pipeline for 2 cycles
        $display(">>> Flush for 2 cycles");
        do_flush(2);

        // allow more cycles to observe streaming
        repeat (8) @(posedge f_clk);

        $display("TEST COMPLETE");
        #10 $finish;
    end

endmodule
