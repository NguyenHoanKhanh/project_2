`timescale 1ns/1ps
`include "./source/fetch_instruction.v"
module tb_instruction_fetch;
    // Parameters
    parameter IWIDTH   = 32;
    parameter AWIDTH   = 32;
    parameter PC_WIDTH  = 32;

    // Clock and reset
    reg                    f_clk;
    reg                    f_rst;

    // Instruction interface
    reg  [IWIDTH-1:0]     f_i_instr;
    wire [IWIDTH-1:0]     f_o_instr;
    wire [AWIDTH-1:0]     f_o_addr_instr;
    wire                   f_o_syn;
    reg                    f_i_ack;

    // Program counter interface
    reg                    f_change_pc;
    reg  [PC_WIDTH-1:0]    f_alu_pc_value;
    wire [PC_WIDTH-1:0]    f_pc;

    // Stall interface
    reg                    f_i_stall;
    wire                   f_o_ce;

    // Instantiate the DUT
    instruction_fetch #(
        .IWIDTH(IWIDTH),
        .AWIDTH(AWIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) dut (
        .f_clk(f_clk),
        .f_rst(f_rst),
        .f_i_instr(f_i_instr),
        .f_o_instr(f_o_instr),
        .f_o_addr_instr(f_o_addr_instr),
        .f_change_pc(f_change_pc),
        .f_alu_pc_value(f_alu_pc_value),
        .f_pc(f_pc),
        .f_o_syn(f_o_syn),
        .f_i_ack(f_i_ack),
        .f_i_stall(f_i_stall),
        .f_o_ce(f_o_ce)
    );

    // Clock generation: 10 ns period
    initial begin
        f_clk = 1'b0;
    end
    always #5 f_clk = ~f_clk;

    initial begin
        $dumpfile("./waveform/fetch.vcd");
        $dumpvars(0, tb_instruction_fetch);
    end

    // Reset task
    task do_reset;
        input integer cycles;
        begin
            f_rst = 0;
            repeat (cycles) @(posedge f_clk);
            f_rst = 1;
            @(posedge f_clk);
        end
    endtask

    // Task to drive one instruction fetch
    task send_instruction (input [IWIDTH - 1 : 0] instr);
        begin
            f_i_instr = instr;
            f_i_ack = 1'b1;
            f_i_stall = 1'b0;
            f_change_pc = 1'b0;
            @(posedge f_clk);
            f_i_ack = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Task to introduce a stall
    task introduce_stall (input integer counter_stall);
        begin
            f_i_stall = 1'b1;
            repeat (counter_stall) @(posedge f_clk);
            f_i_stall = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Task to change PC via jump
    task do_jump (input [PC_WIDTH - 1 : 0] pc_jump);
        begin
            f_alu_pc_value = pc_jump;
            f_change_pc = 1'b1;
            f_i_ack = 1'b1;
            @(posedge f_clk);
            f_change_pc = 1'b0;
            f_i_ack = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Monitoring signals
    initial begin
        $display("Time |   rst  | addr_req | instr_in  | ack | stall | syn | ce_out | pc_out | fetched_instr");
        $monitor("%4t |   %b    | %h  | %h |  %b  |   %b   |  %b  |   %b    | %h | %h", 
                 $time, f_rst, f_o_addr_instr, f_i_instr, f_i_ack, f_i_stall, f_o_syn, f_o_ce, f_pc, f_o_instr);
    end

    // Test sequence
    initial begin
        // Initialize inputs
        f_i_instr        = 32'h00000000;
        f_i_ack          = 0;
        f_i_stall        = 0;
        f_change_pc      = 0;
        f_alu_pc_value   = 32'h00000000;

        // Apply reset
        do_reset(2);

        // Normal fetch sequence: fetch 3 instructions
        send_instruction(32'hA0A0A0A0);
        send_instruction(32'hB1B1B1B1);
        send_instruction(32'hC2C2C2C2);

        // Introduce a stall for 3 cycles
        introduce_stall(3);

        // Continue fetching after stall
        send_instruction(32'hD3D3D3D3);

        // Change PC (jump) to address 0x100
        do_jump(32'h00000100);

        // Fetch 2 more instructions after jump
        send_instruction(32'hE4E4E4E4);
        send_instruction(32'hF5F5F5F5);

        // Finish simulation
        #20;
        $display("Test completed.");
        $finish;
    end
endmodule
