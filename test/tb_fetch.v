`timescale 1ns/1ps
`include "./source/fetch_stage.v"
module tb_instruction_fetch;
    // Parameters
    parameter I_WIDTH   = 32;
    parameter A_WIDTH   = 32;
    parameter PC_WIDTH  = 32;

    // Clock and reset
    reg                    f_clk;
    reg                    f_rst_n;

    // Instruction interface
    reg  [I_WIDTH-1:0]     i_instr;
    wire [I_WIDTH-1:0]     o_instr;
    wire [A_WIDTH-1:0]     o_addr_instr;
    wire                   o_syn;
    reg                    i_ack;

    // Program counter interface
    reg                    change_pc;
    reg  [PC_WIDTH-1:0]    alu_pc_value;
    wire [PC_WIDTH-1:0]    pc;

    // Stall interface
    reg                    i_stall;
    wire                   o_ce;

    // Instantiate the DUT
    instruction_fetch #(
        .I_WIDTH(I_WIDTH),
        .A_WIDTH(A_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) dut (
        .f_clk(f_clk),
        .f_rst_n(f_rst_n),
        .i_instr(i_instr),
        .o_instr(o_instr),
        .o_addr_instr(o_addr_instr),
        .change_pc(change_pc),
        .alu_pc_value(alu_pc_value),
        .pc(pc),
        .o_syn(o_syn),
        .i_ack(i_ack),
        .i_stall(i_stall),
        .o_ce(o_ce)
    );

    // Clock generation: 10 ns period
    initial f_clk = 1'b0;
    always #5 f_clk = ~f_clk;

    initial begin
        $dumpfile("./waveform/fetch.vcd");
        $dumpvars(0, tb_instruction_fetch);
    end

    // Reset task
    task do_reset;
        input integer cycles;
        begin
            f_rst_n = 0;
            repeat (cycles) @(posedge f_clk);
            f_rst_n = 1;
            @(posedge f_clk);
        end
    endtask

    // Task to drive one instruction fetch
    task send_instruction (input [I_WIDTH - 1 : 0] instr);
        begin
            i_instr = instr;
            i_ack = 1'b1;
            i_stall = 1'b0;
            change_pc = 1'b0;
            @(posedge f_clk);
            i_ack = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Task to introduce a stall
    task introduce_stall (input integer counter_stall);
        begin
            i_stall = 1'b1;
            repeat (counter_stall) @(posedge f_clk);
            i_stall = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Task to change PC via jump
    task do_jump (input [PC_WIDTH - 1 : 0] pc_jump);
        begin
            alu_pc_value = pc_jump;
            change_pc = 1'b1;
            i_ack = 1'b1;
            @(posedge f_clk);
            change_pc = 1'b0;
            i_ack = 1'b0;
            @(posedge f_clk);
        end
    endtask

    // Monitoring signals
    initial begin
        $display("Time |   rst  | addr_req | instr_in  | ack | stall | syn | ce_out | pc_out | fetched_instr");
        $monitor("%4t |   %b    | %h  | %h |  %b  |   %b   |  %b  |   %b    | %h | %h", 
                 $time, f_rst_n, o_addr_instr, i_instr, i_ack, i_stall, o_syn, o_ce, pc, o_instr);
    end

    // Test sequence
    initial begin
        // Initialize inputs
        i_instr        = 32'h00000000;
        i_ack          = 0;
        i_stall        = 0;
        change_pc      = 0;
        alu_pc_value   = 32'h00000000;

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
